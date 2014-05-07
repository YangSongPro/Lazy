#!/usr/bin/env bash

# This one should be put on workstation

set -x

js_dir="/tftpboot/dmx/${username}/package"
js_script="/tftpboot/dmx/ertvwxo/package/update_dhcp.sh"

username=$USER
target=""
package=""
official=false
obuild=""
auto_install=false

usage() {
    echo "Usage:"
    echo "      ${cmd} [t:p:o:hi]"
    echo "      -t --target stp      eg. 1006-1, 1006-0"
    echo "      -p --package file    custom package"
    echo "      -o --official file   official build"
    echo "      -h --help            print this help info"
    echo "      -i --install         auto rtfd SCXs after update the dhcp configuration"
    echo
    echo
    exit 0
}

check_console() {
    ip=$1
    port=$2
    expect -c "
        set timeout 5;
        spawn ssh $ip -p $port
        expect {
            \"*yes/no\" {send \"yes\r\";exp_continue}
            \"*password:\" {send \"$password\r\"}
            timeout {puts \"timeout when connect to console\"}
        }
        expect {
            \"*New sniff session*\" {puts \"stp ${target} is used by others!\"; exit 1}
            \"Entering server port, ..... type ^g for port menu.\" {send \"\r\"}
            timeout {puts \"timeout when connect to console\"}
        }
        expect eof
        exit 0
    "
}

login_console() {
    ip=$1
    port=$2
    expect -c "
        set timeout 5;
        spawn ssh $ip -p $port
        expect {
            \"*yes/no\" {send \"yes\r\";exp_continue}
            \"*password:\" {send \"$password\r\"}
            timeout {puts \"timeout when connect to console\"}
        }
        expect {
            \"New sniff session started ...\" {puts \"This stp is used by others!\"}
            \"Entering server port, ..... type ^g for port menu.\" {send \"\r\"}
            timeout {puts \"timeout when connect to console\"}
        }
        sleep 1
        expect {
            \"login:\" {send \"root\r\";exp_continue}
            \"# \" {send \"startsw factorydefault\r\"}
            \"Password:\" {send \"tre,14\r\";exp_continue}
            \"$ \" {send \"su -\r\";exp_continue}
            timeout {puts \"timeout when login to console\"}
        }
        expect eof
        exit
    "
}

read_password() {
    passwd_file=~/.password
    if [[ -e "${passwd_file}" ]]; then
        password=$(cat ~/.password)
    else
        echo -n "For auto installation, input your password: "
        read password
        echo ${password} > ${passwd_file}
        chmod 600 ${passwd_file}
    fi
}

do_rtfd() {
    rtfd_flag=false
    echo "check left console"
    check_console ${console_address} ${left_port}
    if [[ $? -eq 0 ]]; then
        echo "check right console"
        check_console ${console_address} ${right_port}
        if [[ $? -eq 0 ]]; then
            rtfd_flag=true
        fi
    fi
    if [[ ${rtfd_flag} == true ]]; then
        echo "start rtfd the SCX..."
        login_console ${console_address} ${left_port} >/tmp/rtfd_${username}_${target}_left.log 2>&1 &
        login_console ${console_address} ${right_port} >/tmp/rtfd_${username}_${target}_right.log 2>&1 &
        sleep 10
        echo "rtfd is ongoing..."
        check_console ${console_address} ${left_port}
        check_console ${console_address} ${right_port}
    fi
}

set_target_info() {
    if [[ "$target" == "1006-1" ]]; then
        console_address="cs-1007-0"
        left_port=7012
        right_port=7006
    elif [[ "$target" == "1006-0" ]]; then
        console_address="cs-1007-0"
        left_port=7002
        right_port=7001
    else
        echo "Doesn't support this STP!"
        usage
    fi
}

parse_opt() {
    echo "all: $@"
    args=$(getopt -a -o t:p:o:hi -l target:,package:,official:,help,install -- "$@")
    if [[ $? -ne 0 ]]; then
        usage
    fi
    eval set -- ${args}

    while true; do
        echo $1
        case "$1" in
            -t|--target)
            target="$2"
            shift
            ;;
            -p|--package)
            package="$2"
            shift
            ;;
            -o|official)
            official=true
            obuild="$2"
            shift
            ;;
            -h|--help)
            usage
            ;;
            -i|--install)
            auto_install=true
            ;;
            (--)
            shift
            break
            ;;

        esac
    shift
    done
    if [[ -z "$target" ]]; then
        echo "option target must be set!"
        usage
    fi
    if [[ -z "$pakcage" && "$official" == false ]]; then
        echo "one of option package or official must be set!"
        usage
    fi
    if [[ ! -z "$package" && "$official" == true ]]; then
        echo "$package and official build $obuild, which do you want to install?"
        usage
    fi

}

main() {
    echo "start..."
    cmd="$0"
    parse_opt "$@"
    set_target_info
    if [[ "$auto_install" == true ]]; then
        read_password
    fi
    js_package_dir="/tftpboot/dmx/${username}/package/${target}"

    ssh js@js2 "mkdir -p ${js_package_dir} && rm -rf ${js_package_dir}/*"
    flag=false
    if [ "$official" == false ]; then
        filename=$(basename "$package")
        scp "${package}" js@js2:"${js_package_dir}/"
        ssh js@js2 "cd ${js_dir} && bash ${js_script} $target ${js_dir}/${filename} $username"
        if [[ $? -eq 0 ]]; then
            flag=true
        fi
    elif [[ ! -z "$obuild" ]]; then
        ssh js@js2 "cd ${js_dir} && bash ${js_script} $target ${obuild} $username"
        if [[ $? -eq 0 ]]; then
            flag=true
        fi
    fi
    if [[ "$flag" == true && "$auto_install" == true ]]; then
        do_rtfd
    fi
    echo "please login to SCX to see the progress"
}

main "$@"
