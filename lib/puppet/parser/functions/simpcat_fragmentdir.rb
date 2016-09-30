module Puppet::Parser::Functions
    newfunction(:simpcat_fragmentdir, :type => :rvalue, :doc => "Returns the fragment directory for a given SIMP concat build.") do |args|
      puppet_vardir = lookupvar('puppet_vardir')
      if puppet_vardir.nil? || puppet_vardir.strip.empty?
        raise(Puppet::ParseError, 'Could not determine a valid Puppet vardir on the client')
      end

      "#{puppet_vardir}/simpcat/fragments/#{Array(args).flatten.first.strip}"
    end
end
