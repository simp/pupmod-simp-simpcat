module Puppet::Parser::Functions
    newfunction(:concat_output, :type => :rvalue, :doc => "Returns the output file for a given concat build.") do |args|
        "#{Puppet[:vardir]}/concat/output/#{Array(args).flatten.first}.out"
    end
end
