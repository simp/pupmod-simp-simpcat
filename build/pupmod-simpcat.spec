Summary: Concat Puppet Module
Name: pupmod-simpcat
Version: 5.0.0
Release: 0
License: Apache License, Version 2.0
Group: Applications/System
Source: %{name}-%{version}-%{release}.tar.gz
Buildroot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires: puppet >= 3.3.0
Buildarch: noarch
Requires: simp-bootstrap >= 4.2.0
Obsoletes: pupmod-concat
Obsoletes: pupmod-concat-test

Prefix:"/etc/puppet/environments/simp/modules"

%description
This puppet module provides the concat_build and concat_fragment custom types.

%prep
%setup -q

%build

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/simpcat

dirs='files lib manifests templates'
for dir in $dirs; do
  test -d $dir && cp -r $dir %{buildroot}/%{prefix}/simpcat
done

mkdir -p %{buildroot}/usr/share/simp/tests/modules/simpcat

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/simpcat

%files
%defattr(0640,root,puppet,0750)
/etc/puppet/environments/simp/modules/simpcat

%post

%postun
# Post uninstall stuff

%changelog
* Sat Nov 07 2015 Chris Tessmer <chris.tessmer@onyxpoint.com> - 5.0.0-0
- Renamed pupmod-concat to pupmod-simpcat

* Fri Jan 16 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.0.0-3
- Changed puppet-server requirement to puppet

* Thu Aug 07 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.0.0-2
- Updated the concat_output and fragmentdir functions to properly
  handle String/Array conversions in Ruby 2.

* Fri Jun 20 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.0.0-1
- Updated to work with Ruby 2

* Tue Jan 28 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.0.0-0
- Updated several aspects of concat_build to work properly with Puppet
  3.4

* Thu Jan 16 2014 Kendall Moore <kmoore@keywcorp.com> - 2.1.1-3
- Updated provided for concat_build so that empty concat fragments wouldn't error out when
  quiet is set to true.

* Mon Jan 28 2013 Maintenance
2.1.1-2
- Create a test to check concat_build, concat_fragment, concat_output, and fragmentdir using postfix and snmpd modules.

* Mon Sep 10 2012 Maintenance
2.1.1-1
- Fixed a bug where concat_build would explode if a file to be read had no
  content.
- Added an option 'externally_managed' to indicate that the fragment in
  question was to be externally managed. This was mainly done to support Augeas
  building parts of files.

* Thu Jun 07 2012 Maintenance
2.1.1-0
- Ensure that Arrays in templates are flattened.
- Call facts as instance variables.
- Cleaned up a few items that cut down the run time. Most notably added a break
  in the file comparison segment.
- Moved mit-tests to /usr/share/simp...
- Updated the methods to return the proper property values.

* Fri Mar 02 2012 Maintenance
2.1.0-3
- Improved test stubs.

* Fri Feb 10 2012 Maintenance
2.1.0-2
- The concat module was not properly picking up changes from
  submodules.
- Added checking to be sure that an appropriate target is set if using
  parent builds.

* Mon Dec 26 2011 Maintenance
2.1.0-1
- Updated the spec file to not require a separate file list.

* Thu Nov 10 2011 Maintenance - 2.1.0-0
- Massive rewrite for optimization.

* Fri Feb 11 2011 Maintenance - 2.0.0-0
- Initial implementation of concat_build and concat_fragment custom types.
