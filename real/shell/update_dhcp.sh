#!/usr/bin/env bash

# This script should be put on jumpstart

set -x

target=$1
package=$2
myself=$3

package_dir="dmx/$myself/package/${target}"
tftp_package_dir="/tftpboot/$package_dir"
template_dir="/tftpboot/dmx/ertvwxo/package/template"

set_target_info() {
    if [[ $target == "1006-1" ]]; then
        scx_version="CXC1732063"
    elif [[ $target == "1006-0" ]]; then
        scx_version="CXC1729926"
    elif [[ $target == "CXC1732063" ]]; then
        scx_version="CXC1732063"
    else
        echo "Doesn't support this STP!"
        exit 1
    fi
}

unpack_dmx() {
    tar xf "${package}" -C "${tftp_package_dir}" && tar zxf "${tftp_package_dir}/SCX.tgz" -C "${tftp_package_dir}"
    dmx_rstate=$(grep "CXP9016673" ${tftp_package_dir}/dmx-metadata.xml | sed -e "s/<product name=\"DMX\" id=\"CXP9016673\" rstate=\"//" | sed -e "s/\"\/>//" | tr -d " ")
    echo "dmx_rstate: $dmx_rstate"
    scx_rstate=$(grep "${scx_version}" ${tftp_package_dir}/scx-metadata.xml | sed -e "s/<product name=\"scx\" id=\"${scx_version}\" rstate=\"//" | sed -e "s/\"\/>//" | tr -d " ")
    echo "scx_rstate: $scx_rstate"
    link_dmx_package="$package_dir/DMX.$dmx_rstate.tar"
    ln -s ${package} "$tftp_package_dir/DMX.$dmx_rstate.tar"
    link_scx_package="$package_dir/SCX.$scx_rstate.tar"
    ln -s "${tftp_package_dir}/${scx_version}/SCX.tar" "${tftp_package_dir}/SCX.$scx_rstate.tar"
}

update_dhcp_conf() {
    echo "update_dhcp_conf"
    dhcp_conf="/etc/dhcpd.conf.d/subracks/Ki${target}.dhcpd.conf"
    dhcp_conf_bak="${dhcp_conf}.auto.bak"
    dhcp_conf_tmp="/tftpboot/dmx/$myself/package/Ki${target}.dhcpd.conf.tmp"
    dhcp_conf_template="${template_dir}/Ki${target}.dhcpd.conf"

    if [ ! -e $dhcp_conf_bak ];  then
        cp ${dhcp_conf} ${dhcp_conf_bak}
    fi
    sed -e "s#DMX_PACKAGE#\"${link_dmx_package}\"#" \
        -e "s/DMX_VERSION/${dmx_rstate}/"  \
        -e "s#SCX_PACKAGE#\"${link_scx_package}\"#" \
        -e "s/SCX_VERSION/SCX_${scx_version}_${scx_rstate}/" \
    ${dhcp_conf_template} > ${dhcp_conf_tmp}
    mv ${dhcp_conf_tmp} ${dhcp_conf}
}

restart_dhcp() {
    sudo /etc/init.d/dhcpd restart
}

set_target_info
mkdir -p "${tftp_package_dir}"
cd "${tftp_package_dir}"
unpack_dmx
update_dhcp_conf
restart_dhcp
