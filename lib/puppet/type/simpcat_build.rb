Puppet::Type.newtype(:simpcat_build) do
  @doc = "Build file from SIMP concat fragments"

  def extractexe(cmd)
    # easy case: command was quoted
    if cmd =~ /^"([^"]+)"/
      $1
    else
      cmd.split(/ /)[0]
    end
  end

  def validatecmd(cmd)
    exe = extractexe(cmd)
    fail Puppet::Error, "'#{cmd}' is unqualifed" if File.expand_path(exe) != exe
  end

  newparam(:name, :namevar => true) do
    validate do |value|
      fail Puppet::Error, "concat_name cannot include '../'!" if value =~ /\.\.\//
    end
  end

  newparam(:clean_comments) do
    desc "If a line begins with the specified string it will not be printed in the output file."
  end

  newparam(:clean_whitespace) do
    desc "Cleans whitespace.  Can be passed an array.  'lines' will cause the
          output to not contain any blank lines. 'all' is equivalent to
          [leading, trailing, lines]"
    munge do |value|
      [value].flatten!
      if value.include?('all') then
        return ['leading', 'trailing', 'lines']
      end
      [value].flatten.uniq
    end

    validate do |value|
      [value].flatten!
      if value.include?('none') and value.uniq.length > 1 then
        fail Puppet::Error, "You cannot specify 'none' with any other options"
      end
    end

    newvalues(:leading, :trailing, :lines, :all, :none)
    defaultto [:none]
  end

  newparam(:file_delimiter) do
    desc "Acts as the delimiter between concatenated file fragments. For
	  instance, if you have two files with contents 'foo' and 'bar', the
	  result with a file_delimiter of ':' will be a file containing
          'foo:bar'."
    defaultto "\n"
  end

  newparam(:onlyif) do
    desc "Copy file to target only if this command exits with status '0'"
    validate do |cmds|
      [cmds].flatten!

      [cmds].each do |cmd|
        @resource.validatecmd(cmd)
      end
    end

    munge do |cmds|
      [cmds].flatten
    end
  end

  newparam(:sort, :boolean => true) do
    desc "Sort the built file. This tries to sort in a human fashion with
	  1 < 2 < 10 < 20 < a, etc..  sort. Note that this will need to read
          the entire file into memory

          Example Sort:

          ['a','1','b','10','2','20','Z','A']

          translates to

          ['1','2','10','20','a','A','b','Z']

          Note: If you use a file delimiter with this, it *will not* be sorted!"
    newvalues(:true, :false)
    defaultto :false
  end

  newparam(:squeeze_blank, :boolean => true) do
    desc "Never output more than one blank line"
    newvalues(:true, :false)
    defaultto :false
  end

  newparam(:target) do
    desc "Fully qualified path to copy output file to"
    validate do |path|
      unless path =~ /^\/$/ or path =~ /^\/[^\/]/
        fail Puppet::Error, "File paths must be fully qualified, not '#{path}'"
      end
    end
  end

  newparam(:parent_build) do
    desc "Specify the parent to this build step. Only needed for multiple
          staged builds. Can be an array. It does not make sense to specify
          a parent build without setting the target to the parent's fragment
          directory."
  end

  newparam(:quiet, :boolean => true) do
    desc "Suppress errors when no fragments exist for build"
    newvalues(:true, :false)
    defaultto :false
  end

  newparam(:unique) do
    desc "Only print unique lines to the output file. Sort takes precedence.
          This does not affect file delimiters.

	  true: Uses Ruby's Array.uniq function. It will remove all duplicates
          regardless  of where they are in the file.

	  uniq: Acts like the uniq command found in GNU coreutils and only
          removes consecutive duplicates."

    newvalues(:true, :false, :uniq)
    defaultto :false
  end

  newproperty(:order, :array_matching => :all) do
    desc "Array containing ordering info for build"

    defaultto ["*"]

    def retrieve
      return resource[:order].join(',')
    end

    def insync?(is)
      provider.register

      f_base = "#{Facter.value(:puppet_vardir)}/simpcat/output/#{@resource[:name]}"

      provider.build_file(f_base)

      if provider.check_onlyif then
        if resource[:target] then
          return !provider.file_diff("#{f_base}.out",resource[:target])
        elsif File.exist?("#{f_base}.prev") then
          retval = !provider.file_diff("#{f_base}.out","#{f_base}.prev")
          FileUtils.rm("#{f_base}.prev")
          return retval
        end
      end

      return true
    end

    def sync
      provider.sync_file
    end

    def change_to_s(currentvalue, newvalue)
      "#{[newvalue].join(',')} used for ordering"
    end
  end

  autorequire(:simpcat_build) do
    req = []
    # resource contains all simpcat_build resources from the catalog that are
    # children of this simpcat_build
    resource = catalog.resources.find_all { |r| r.is_a?(Puppet::Type.type(:simpcat_build)) and r[:parent_build] and Array(r[:parent_build]).flatten.include?(self[:name]) }
    if not resource.empty? then
      req << resource
    end
    req.flatten!
    req
  end

  autorequire(:simpcat_fragment) do
    req = []
    # resource contains all simpcat_fragment resources from the catalog that
    # belog to this simpcat_build
    resource = catalog.resources.find_all { |r| r.is_a?(Puppet::Type.type(:simpcat_fragment)) and r[:name] =~ /^#{self[:name]}\+.+/ }
    if not resource.empty? then
      req = resource
    elsif not self[:quiet] then
      err "No fragments specified for group #{self[:name]}!"
    end
    # Clean up the fragments directory for this build if there are no fragments
    # in the catalog.
    #
    # Otherwise, clean up the fragment space in case some have changed names.
    if resource.empty? and File.directory?("#{Facter.value(:puppet_vardir)}/simpcat/fragments/#{self[:name]}") then
      debug "Removing: #{Facter.value(:puppet_vardir)}/simpcat/fragments/#{self[:name]}"
      FileUtils.rm_rf("#{Facter.value(:puppet_vardir)}/simpcat/fragments/#{self[:name]}")
    else
      (Dir.glob("#{Facter.value(:puppet_vardir)}/simpcat/fragments/#{self[:name]}/*").map{|x| File.basename(x)} - req.map{|x| x[:name].split('+')[1..-1].join('+')}).each do |todel|
        debug "Removing: #{Facter.value(:puppet_vardir)}/simpcat/fragments/#{self[:name]}/#{todel}"
        FileUtils.rm_f("#{Facter.value(:puppet_vardir)}/simpcat/fragments/#{self[:name]}/#{todel}")
      end
    end
    if self[:parent_build] then
      if not self[:target] then
        err "No target specified when using parent_build.  Target needs to be the fragment directory for one of the parents."
      end
      found_parent = false
      found_parent_target = false
      Array(self[:parent_build]).flatten.each do |parent_build|
        # Checks to see if there is a simpcat_build for each parent_build specified
        if catalog.resource("Simpcat_build[#{parent_build}]") then
          found_parent = true
        elsif not self[:quiet] then
          warning "No simpcat_build found for parent_build #{parent_build}"
        end

        if File.dirname(self[:target]).eql?("#{Facter.value(:puppet_vardir)}/simpcat/fragments/#{parent_build}")
          found_parent_target = true
        elsif not self[:quiet] then
          warning "Target dirname = #{File.dirname(self[:target])}, parent dir = #{Facter.value(:puppet_vardir)}/simpcat/fragments/#{parent_build}"
        end
        # frags contains all simpcat_fragment resources for the parent simpcat_build
        frags = catalog.resources.find_all { |r| r.is_a?(Puppet::Type.type(:simpcat_fragment)) and r[:name] =~ /^#{parent_build}\+\w/ }
        if not frags.empty? then
          req << frags
        end
      end
      if not found_parent then
        err "No simpcat_build found for any of #{Array(self[:parent_build]).join(",")}"
      end
      if not found_parent_target then
        err "Target directory is not #{Facter.value(:puppet_vardir)}/simpcat/fragments/<parent>"
      end
    end
    req.flatten!
    req
  end
end
