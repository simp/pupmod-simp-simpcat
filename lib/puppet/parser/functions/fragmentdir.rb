module Puppet::Parser::Functions
    newfunction(:fragmentdir, :type => :rvalue, :doc => "Returns the fragment directory for a given concat build.") do |args|
        "#{Puppet[:vardir]}/concat/fragments/#{Array(args).flatten.first}"
    end
end
