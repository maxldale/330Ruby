require "digest"
require "securerandom"
require "sqlite3"

#
# Constants
#

AVATAR_DIR = "./public/avatars/"
SESSION_BITS = 32
TOKEN_BITS = 16
DATE_FMT = "%d %h %G at %R"

#
# Helpers
#

# upload_file : String File -> Boolean
# Uploads a file to the server (failing if it already exists)
# and returns success status.
def upload_file(filename, file)
	files = Dir.entries(".").reject {|f| File.directory?(f) }
	path = "#{AVATAR_DIR}/#{filename}"
	return false if not check_file filename
	return false if File.exists? path
	File.open(path, "wb") { |f| f.write(file.read) }
	true
end

def clean_filename(filename)
	filename =~ /[a-zA-z0-9]*[\.png|\.jpg]?/
end

def check_file(filename)
	files = Dir.entries(AVATAR_DIR).reject {|f| File.directory?(f) }
	if files.member? filename
		true
	elsif clean_filename filename
		
	else
		false
	end
end

def filter_avatar(avatar)
	if check_file(avatar)
		avatar
	else
		"dummy"
	end
end

#
# Sessions
#
# The Sessions module handles session identifiers, integers
# which uniquely identify a user on a particular client.
# Once issued, these identifiers will automatically be stored
# in a cookie on the user's browser. We keep track of which
# identifiers belong to whom.
#

module Sessions

	# issue_session : -> Integer
	# Returns cryptographically secure session identifier.
	def issue_session
		SecureRandom.random_number(2 ** SESSION_BITS)
	end

	# assign_session : String -> Integer
	# Assigns a session identifier to a user and returns it.
	def assign_session(user)
		@sessions[user] = issue_session
	end

	# revoke_session : String -> Integer
	# Revokes session of a user and returns it.
	def revoke_session(user)
		@sessions.delete user
	end
end

#
# Tokens
#
# The Tokens module generates and assigns tokens which are
# attached to user input forms as a hidden field. A new token
# should be assigned to a user on GET requests (where the
# page has a form).
#

module Tokens

	# issue_token : -> Integer
	# Returns cryptographically secure token.
	def issue_token
		SecureRandom.random_number(2 ** TOKEN_BITS)
	end

	# assign_token : String -> Integer
	# Assigns a token identifier to a user and returns it.
	def assign_token(user)
		@tokens[user] = issue_token
	end
end

#
# Access
#
# The Access module handles user authentication and authorization.
# We verify the user's identity by matching up the session identifier
# the user gives us (as a cookie) to the identifier we issued for that
# user at login.
#

module Access

	# authenticate : String String -> (Integer or NilClass)
	# If credentials are valid, assigns session identifier to user
	# and returns identifier, otherwise returns nil.
	def authenticate(user, passwd)
		assign_session user if authenticate_user(user, passwd)
	end

	# authorize : String Integer -> Boolean
	# Returns whether user was issued given session identifier.
	def authorize(user, session)
		session == @sessions[user]
	end

	# revoke : String Integer -> (Integer or NilClass)
	# Revokes a user's session so long as given session identifier
	# is valid. Returns the session if valid, otherwise nil.
	def revoke(user, session)
		revoke_session user if authorize(user, session)
	end
end

#
# User
#
# The User module handles all user-creating, modifying, and
# data retrieval actions.
#

module User

    # search : String -> Hash
    # Returns a hash containing the search query and the set of
    # users matching the query (by name or description).
    def search(user_query)
        users = []
        updated_query = "%" + user_query + "%"
        query = %{
        SELECT User, Avatar, Description
        FROM Users
        WHERE User LIKE ? OR
	    Description LIKE ?
        }
        @db.execute(query, [updated_query, updated_query]) do |user|
            users << {
                :name => Rack::Utils.escape_html(user[0]),
                :avatar => filter_avatar(user[1]),
                :description => Rack::Utils.escape_html(user[2])
            }
        end
        { :query => user_query, :users => users }
    end
        

	# register : String String File String String -> Boolean
	# Registers a new user if they don't already exist and
	# password and confirm password match. Returns success status.
	def register(user, filename, file, password, confirm)
		return false if password != confirm
		if (get_user(user) == nil)
			if not upload_file(filename, file)
				filename = "dummy"
			end
			random = SecureRandom.random_number(2 ** SESSION_BITS)
			salt = Digest::SHA256.hexdigest(random.to_s)
			passHash = Digest::SHA256.hexdigest(password + salt)
			query = %{
			INSERT INTO Users(User, Password, Avatar, Salt)
			VALUES (?, ?, ?, ?)
			}
			@db.execute(query, [user, passHash, filename, salt])
			true
		else
			false
		end
	end
	
	def get_salt(user)
		salt = ''
		query = %{
		SELECT Salt
		FROM Users
		WHERE User = ?
		}
		@db.execute(query, user) do |user|
			salt = user[0]
		end
		salt
	end
	
	def authenticate_user(user, password)
		salt = get_salt(user)
		return nil if salt == ''
		hashed_pass = Digest::SHA256.hexdigest(password + salt)
		query = %{
		SELECT Avatar, Description
		FROM Users
		WHERE User = ?
		AND Password = ?
		}
		@db.execute(query, [user,hashed_pass]) do |user|
			return {
				:avatar => filter_avatar(user[0]),
				:description => Rack::Utils.escape_html(user[1])
			}
		end
		nil
	end

	# get_user: String -> (Hash or NilClass)
	# Gets user preferences of given user or nil if non-existent
	def get_user(user)
		query = %{
		SELECT Avatar, Description
		FROM Users
		WHERE User = ?
		}
		@db.execute(query, user) do |user|
			return {
				:avatar => filter_avatar(user[0]),
				:description => Rack::Utils.escape_html(user[1])
			}
		end
		nil
	end

	# update_prefs : String Integer String Integer -> Boolean
	# Update preferences of given user returning success status.
	def update_prefs(user, session, description, token)
		return false if token != @tokens[user]
		return false if session != @sessions[user]
		query = %{
		UPDATE Users
		SET Description = ?
		WHERE User = ?
		}
		@db.execute(query, [description, user])
		true
	end
end

#
# Epsilons
#
# The Epsilons module is concerned with creating and retrieving
# epsilons. These are the little messages that make up communication
# on our network.
#

module Epsilons

	# publish_epsilon : String Integer String Integer -> Boolean
	# Publish epsilon from user with given content. Returns
	# success status.
	def publish_epsilon(user, session, content, token)
		return false if token != @tokens[user]
		return false if session != @sessions[user]
		timestamp = Time.now.to_i
		query = %{
		INSERT INTO Epsilons(User, Content, Date)
		VALUES (?, ?, ?)
		}
		@db.prepare(query).execute([user, content, timestamp])
		true
	end

	# get_epsilons : (String or NilClass) -> Array
	# Returns array of all epsilons from the given user or all epsilons
	# in the system if given nil.
	def get_epsilons(user)
		epsilons = []
		query = %{
		SELECT Epsilons.User, Avatar, Content, Date
		FROM Epsilons
		JOIN Users ON Epsilons.User = Users.User
		#{"WHERE Epsilons.User = '#{user}'" if user}
		ORDER BY Epsilons.ID DESC
		}
		@db.execute(query) do |eps|
			date_str = Time.at(eps[3]).strftime(DATE_FMT)
			epsilons << {
				:user => Rack::Utils.escape_html(eps[0]),
				:avatar => filter_avatar(eps[1]),
				:content => Rack::Utils.escape_html(eps[2]),
				:date => date_str
			}
		end
		epsilons
	end

	# all_epsilons : -> Array
	# Returns all epsilons.
	def all_epsilons
		get_epsilons nil
	end
end

#
# Controller
#
# The Controller class defines a single interface to all the
# previously defined modules. It holds the server-side state
# of the application as well as the database handle.
#

class Controller
	include Sessions
	include Tokens
	include Access
	include User
	include Epsilons

	# Leave @db as attr_accessor or you will fail the tests!
	attr_accessor :db

	def initialize
		@db = SQLite3::Database.new "data.db"
		@sessions = {}
		@tokens = {}
	end
end
