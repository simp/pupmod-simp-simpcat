Puppet::Type.type(:simpcat_build ).provide :simpcat_build do
  require 'fileutils'

  desc "simpcat_build provider"

  def build_file(f_base)
    if File.directory?("#{Facter.value(:puppet_vardir)}/simpcat/fragments/#{@resource[:name]}") then
      File.exist?("#{f_base}.out") and FileUtils.mv("#{f_base}.out","#{f_base}.prev")

      if not File.directory?(File.dirname(f_base)) then
        FileUtils.mkdir_p(File.dirname(f_base))
      end

      outfile = File.open("#{f_base}.out", "w+")
      input_lines = Array.new
      Dir.chdir("#{Facter.value(:puppet_vardir)}/simpcat/fragments/#{@resource[:name]}") do
        # Clean up anything that shouldn't be here.

        if File.exist?('.~simpcat_fragments') then
          (Dir.glob('*') - File.read(".~simpcat_fragments").split("\n").map{|x| x.chomp}).each do |file|
            FileUtils.rm(file)
          end

          FileUtils.rm('.~simpcat_fragments')
        end

        Array(@resource[:order]).flatten.each do |pattern|

           Dir.glob(pattern).sort_by{ |k| human_sort(k) }.each do |file|

            File.stat(file).size == 0 and next

            prev_line = nil
            File.open(file).each do |line|

              if @resource.squeeze_blank? and line =~ /^\s*$/ then
                if prev_line == :whitespace then
                  next
                else
                   prev_line = :whitespace
                end
              end

              out = clean_line(line)
              if not out.nil? then
		            # This is a bit hackish, but it would be nice to keep as much
          		  # of the file out of memory as possible in the general case.
                if @resource.sort? or not @resource[:unique].eql?(:false) then
                  input_lines.push(line)
                else
		                outfile.puts(line)
                end
              end

            end

            if not @resource.sort? and @resource[:unique].eql?(:false) then
              # Separate the files by the specified delimiter.
              outfile.seek(-1, IO::SEEK_END)
              if outfile.getc.chr.eql?("\n") then
                outfile.seek(-1, IO::SEEK_END)
                outfile.print(String(@resource[:file_delimiter]))
              end
            end
          end
        end
      end

      if not input_lines.empty? then
        if @resource.sort? then
          input_lines = input_lines.sort_by{ |k| human_sort(k) }
        end
        if not @resource[:unique].eql?(:false) then
          if @resource[:unique].eql?(:uniq) then
            require 'enumerator'
            input_lines = input_lines.enum_with_index.map { |x,i|
              if x.eql?(input_lines[i+1]) then
                nil
              else
                x
              end
            }.compact
          else
            input_lines = input_lines.uniq
          end
        end

        outfile.puts(input_lines.join(@resource[:file_delimiter]))
      else
        # Ensure that the end of the file is a '\n'
        outfile.seek(-(String(@resource[:file_delimiter]).length), IO::SEEK_END)
        curpos = outfile.pos
        if not outfile.getc.chr.eql?("\n") then
          outfile.seek(curpos)
          outfile.print("\n")
        end
        outfile.truncate(outfile.pos)
      end

      outfile.close
    elsif not @resource[:quiet] then
      fail Puppet::Error,"The fragments directory at '#{Facter.value(:puppet_vardir)}/simpcat/fragments/#{@resource[:name]}' does not exist!"
    end
  end

  def check_onlyif
    success = true

    if @resource[:onlyif] then
      cmds = [@resource[:onlyif]].flatten
      cmds.each do |cmd|
        return false unless check_command(cmd)
      end
    end

    success
  end

  # Does a comparison of two files and returns true if they differ and false if
  # they do not.
  def file_diff(src, dest)
    if not File.exist?(src) then
      # We want to just say that the files don't differ if we're in quiet mode
      # so that we can skip any further work due to the source file not
      # existing.
      @resource[:quiet] and return false
      fail Puppet::Error,"Could not diff non-existant source file #{src}."
    end

    # If the destination isn't there, it's different.
    return true unless File.exist?(dest)

    # If the sizes are different, it's different.
    return true if File.stat(src).size != File.stat(dest).size

    # If we've gotten here, brute force by 512B at a time. Stop when a chunk differs.
    s_file = File.open(src,'r')
    d_file = File.open(dest,'r')

    retval = false
    while not s_file.eof? do
      if s_file.read(512) != d_file.read(512) then
        retval = true
        break
      end
    end

    s_file.close
    d_file.close
    return retval
  end

  def sync_file
    begin
      if @resource[:target] and check_onlyif then
        debug "Copying #{Facter.value(:puppet_vardir)}/simpcat/output/#{@resource[:name]}.out to #{@resource[:target]}"
        FileUtils.cp("#{Facter.value(:puppet_vardir)}/simpcat/output/#{@resource[:name]}.out", @resource[:target])
      elsif @resource[:target] then
        debug "Not copying to #{@resource[:target]}, 'onlyif' check failed"
      elsif @resource[:onlyif] then
        debug "Specified 'onlyif' without 'target', ignoring."
      end
    rescue Exception => e
      fail Puppet::Error, e unless @resource[:quiet]
    end
  end

  def register
    begin
      if @resource[:parent_build] then
        Array(@resource[:parent_build]).flatten.each do |parent_build|
          if "#{Facter.value(:puppet_vardir)}/simpcat/fragments/#{parent_build}".eql?(File.dirname(@resource[:target])) then
            FileUtils.mkdir_p(File.dirname(@resource[:target]))

            frags_record = "#{File.dirname(@resource[:target])}/.~simpcat_fragments"

            target_shortname = File.basename(@resource[:target])

            fh = File.open(frags_record,'a')
            fh.puts(target_shortname)
            fh.close
          end
        end
      end
    rescue Exception => e
      fail Puppet::Error, e
    end
  end

  private

  # Return true if the command returns 0.
  def check_command(value)
    output = Puppet::Util::Execution.execute([value],{:failonfail => false})
    # The shell returns 127 if the command is missing.
    if output.exitstatus == 127
      raise ArgumentError
    end

    output.exitstatus == 0
  end

  def clean_line(line)
    newline = nil
    if Array(@resource[:clean_whitespace]).flatten.include?('leading') then
      line.sub!(/\s*$/, '')
    end
    if Array(@resource[:clean_whitespace]).flatten.include?('trailing') then
      line.sub!(/^\s*/, '')
    end
    if not (Array(@resource[:clean_whitespace]).flatten.include?('lines') and line =~ /^\s*$/) then
      newline = line
    end
    if @resource[:clean_comments] and line =~ /^#{@resource[:clean_comments]}/ then
      newline = nil
    end
    newline
  end

  def human_sort(obj)
    # This regex taken from http://www.bofh.org.uk/2007/12/16/comprehensible-sorting-in-ruby
    obj.to_s.split(/((?:(?:^|\s)[-+])?(?:\.\d+|\d+(?:\.\d+?(?:[eE]\d+)?(?:$|(?![eE\.])))?))/ms).map { |v| Float(v) rescue v.downcase}
  end

end
