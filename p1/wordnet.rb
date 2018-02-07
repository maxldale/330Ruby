require_relative "graph.rb"

#NOTE: We may assume correct arg types
#However, it's still a good habit to check    	
class Synsets
    def initialize
    	@synsets = Hash.new
    	@synsets.default = []
    end

    def load(synsets_file)
    	if !File.exist? synsets_file
    		raise Exception, "Synsets: load: synsets_file does NOT exist"
    	elsif !File.file? synsets_file
    		raise Exception, "Synsets: load: synsets_file NOT a file"
    	else
    		file_lines = File.readlines(synsets_file)
    		success_lines = Hash.new
    		error_lines = []
    		index = 1
    		file_lines.each { |line|
    			pattern = /^id: (\d+) synset: ((\w+[,]?)+)$/
    			if pattern.match? line
    				res = pattern.match(line)
    				id = res[1].to_i
    				synset = res[2].split(',')
    				if lookup(id).empty?
    					if !success_lines[id].is_a? Array
    						puts "success #{id}"
    						success_lines[id] = synset
    					else
    						#A previous line includes this ID, line invalid
    						error_lines.push(index)
    						puts "fail #{id}"
    					end
    				else
    					#Synset already contains this ID, line invalid
    					error_lines.push(index)
    					puts "fail #{id}"
    				end
    			else
    				#Failed to match on pattern, line invalid
    				error_lines.push(index)
    				puts "fail #{line}"
    			end
    			index = index + 1
    		}
    		#Gone through all lines, check for invalid lines
    	end
    	puts success_lines.size
    	puts success_lines
    	if error_lines.empty?
    		success_lines.keys.each do |id|
    			puts id
    			if !addSet(id, success_lines[id])
    				raise Exception, "Synsets: load: id: #{id} exists already!"
    			end
    				return nil #Everything checked out and was added
    		end
    	else
    		return error_lines #These lines didn't check out, no changes
    	end
    end

    def addSet(synset_id, nouns)
        if !synset_id.is_a? Integer
        	raise Exception, "Synsets: addSet: synset_id NOT an Integer!"
        elsif !nouns.is_a? Array
        	raise Exception, "Synsets: addSet: nouns NOT an Array!"
        elsif synset_id < 0
        	return false #synset_id is negative
        elsif nouns.empty?
        	return false #nouns is empty
        elsif !lookup(synset_id).empty?
        	puts "id exists? #{synset_id}"
        	return false #synset_id already exists
        else
        	puts "adding #{synset_id}"
        	@synsets[synset_id] = nouns
        	return true #added synset_id and nouns to synsets
        end
    end

    def lookup(synset_id)
        @synsets[synset_id]
    end

    def findSynsets(to_find)
        raise Exception, "Not implemented"
    end
    
    p_v = "./inputs/public_synsets_valid"
    p_i = "./inputs/public_synsets_invalid"
    s = Synsets.new
    puts "\" #{s.load(p_v)} \""
    puts "\" #{s.load(p_i)} \""
    puts @synsets.inspect
end

class Hypernyms
    def initialize
    end

    def load(hypernyms_file)
        raise Exception, "Not implemented"
    end

    def addHypernym(source, destination)
        raise Exception, "Not implemented"
    end

    def lca(id1, id2)
        raise Exception, "Not implemented"
    end
end

class CommandParser
    def initialize
        @synsets = Synsets.new
        @hypernyms = Hypernyms.new
    end

    def parse(command)
        raise Exception, "Not implemented"
    end
end
