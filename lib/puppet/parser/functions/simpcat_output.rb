module Puppet::Parser::Functions
    newfunction(:simpcat_output, :type => :rvalue, :doc => "Returns the output file for a given SIMP concat build.") do |args|
        "#{Puppet[:vardir]}/simpcat/output/#{Array(args).flatten.first}.out"
    end
end
