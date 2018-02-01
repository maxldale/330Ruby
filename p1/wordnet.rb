require_relative "graph.rb"

class Synsets
    def initialize
    end

    def load(synsets_file)
        raise Exception, "Not implemented"
    end

    def addSet(synset_id, nouns)
        if !synset_id.is_a? Integer
        	raise Exception, "Synsets: addSet: synset_id NOT an Integer!"
        elsif !nouns.is_a? Array
        	raise Exception, "Synsets: addSet: nouns NOT an Array!"
        elsif synset_id < 0
        	return false #synset_id is negative
        elseif nouns.empty?
        	return false #nouns is empty
        elseif !lookup(synset_id).empty?
        	return false #synset_id already exists
        els
        	raise Exception, "Not implemented"
        end
    end

    def lookup(synset_id)
        raise Exception, "Not implemented"
    end

    def findSynsets(to_find)
        raise Exception, "Not implemented"
    end
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
