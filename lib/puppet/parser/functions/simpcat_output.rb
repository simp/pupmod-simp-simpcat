module Puppet::Parser::Functions
    newfunction(:simpcat_output, :type => :rvalue, :doc => "Returns the output file for a given SIMP concat build.") do |args|
      puppet_vardir = lookupvar('puppet_vardir')
      if puppet_vardir.nil? || puppet_vardir.strip.empty?
        raise(Puppet::ParseError, 'Could not determine a valid Puppet vardir on the client')
      end

        "#{puppet_vardir}/simpcat/output/#{Array(args).flatten.first}.out"
    end
end
