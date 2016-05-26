module Puppet::Parser::Functions
    newfunction(:fragmentdir, :type => :rvalue, :doc => "Returns the fragment directory for a given concat build.") do |args|
      puppet_vardir = lookupvar('puppet_vardir')
      if puppet_vardir.nil? || puppet_vardir.strip.empty?
        raise(Puppet::ParseError, 'Could not determine a valid Puppet vardir on the client')
      end

      "#{puppet_vardir}/concat/fragments/#{Array(args).flatten.first.strip}"
    end
end
