
# inspired by http://blogs.thehumanjourney.net/oaubuntu/entry/kvm_vmbuilder_puppet_really_automated

define cosmos::kvm(
  $domain,
  $ip,
  $netmask,
  $resolver,
  $gateway,
  $repo,
  $tagpattern,
  $suite='precise',
  $bridge='br0',
  $memory='512',
  $rootsize='20G',
  $cpus = '1',
  ) {

  file { "/var/tmp/firstboot_${name}":
     ensure => file,
     content => "#!/bin/sh\nuserdel -r ubuntu; cd /root && sed -i \"s/${name}.${domain}//g\" /etc/hosts && /root/bootstrap-cosmos.sh ${name} ${repo} ${tagpattern} && cosmos update ; cosmos apply\n"
  } ->

  file { "/var/tmp/files_${name}":
     ensure => file,
     content => "/root/cosmos_1.2-2_all.deb /root\n/root/bootstrap-cosmos.sh /root\n"
  } ->

  exec { "check_kvm_enabled_${name}":
    command => "/usr/sbin/kvm-ok",
  } ->

  exec { "create_cosmos_vm_${name}":
    path          => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    timeout       => 3600,
    environment   => ["TMPDIR=/var/tmp",
                      ],
    command       => "virsh destroy $name || true ; virsh undefine $name || true ; /usr/bin/vmbuilder \
      kvm ubuntu  -d /var/lib/libvirt/images/$name -m $memory --cpus $cpus --rootsize $rootsize \
      --domain $domain --bridge $bridge --ip $ip --mask $netmask --gw $gateway --dns $resolver \
      --hostname $name --ssh-key /root/.ssh/authorized_keys --suite $suite --flavour virtual --libvirt qemu:///system \
      --verbose --firstboot /var/tmp/firstboot_${name} --copy /var/tmp/files_${name} \
      --addpkg unattended-upgrades > /var/tmp/vm-$name-install.log 2>&1 && virsh start $name" ,
    unless        => "/usr/bin/test -d /var/lib/libvirt/images/${name}",
    require       => [Package['python-vm-builder']]
  }

}
