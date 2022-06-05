#!/bin/bash
#============create block height agent script here =================

# use this for variable acccess from source file 
# main | grep  'name' | cut -d : -f 2

#--------- OS Distribution --------------------------------
 UNAMESTR=$(uname)

#--------Check if curl is installed----------------------------------
    if [ "$(dpkg -l | awk '/curl/ {print }'|wc -l)" -ge 1 ]; then
        echo -e "\e[36mWelcome to Node Block height service from\e[0m \e[40;38;5;82m Dabble \e[30;48;5;82m Lab \e[0m"
        echo -e "\e[36mTo set up notification you need a sendgrid account (https://sendgrid.com/).\e[0m"

#--------Give user notification-------------------------------------
    if [[ "$UNAMESTR" == 'Darwin' ]]; then
        echo -e "\e[36mThis script has not been tested on this distribution yet.In case of an error create an issue on github\e[0m"
    fi

    else
        echo "Install curl to continue"
        exit 1 
    fi

#--------Set up recieving email----------------------------------------
    echo -e "\e[33mEnter user running pocket service\e[0m"
    read user
    HOME_DIR=$(getent passwd "$user" | cut -d: -f6)
    cd $HOME_DIR
    mkdir -p $HOME_DIR/.secret/config 
    declare -p user > $HOME_DIR/.secret/config/keys

    echo -e "\e[33mEnter email to recieve notifications \e[0m"

    read email_to 
    declare -p email_to >> $HOME_DIR/.secret/config/keys  
#--------Set up sending email-------------------------------------------
    echo -e "\e[33mEnter email from which to send notifications \e[0m"
    
    read email_from 
    declare -p email_from >> $HOME_DIR/.secret/config/keys
#--------Set up name of sender------------------
    echo -e "\e[33mEnter sender name \e[0m"
    
    read name
    declare -p name >> $HOME_DIR/.secret/config/keys
#---------Set up Subject of the email ----------------------------------
    echo -e "\e[33mEnter the Subject of the email notification \e[0m"

    read subject
    declare -p subject >> $HOME_DIR/.secret/config/keys
#----------Set up block height threshold -------------------------------
    echo -e "\e[33mEnter the threshold number of blocks (minimum 2 blocks) \e[0m"
    echo -e "\e[36mPress enter to leave it at the default 4 blocks \e[0m"

    read numberofblocks
    if ! [ "$numberofblocks" -eq "$numberofblocks" ] 2> /dev/null 
    then 
        echo "Defaulting to 4 blocks"
        numberofblocks=4
        declare -p numberofblocks >> $HOME_DIR/.secret/config/keys
    else
        if [[ $numberofblocks -gt 2 ]]; then
         echo "Setting user preference"
        declare -p numberofblocks >> $HOME_DIR/.secret/config/keys
    else
        numberofblocks=4
        declare -p "$numberofblocks" >> $HOME_DIR/.secret/config/keys
        echo "Setting default 4 blocks"
    fi 
    fi
#-------- Set up API Key-------------------------------------------------
    echo -e "\e[33mFinally enter the Sendgrid API Key \e[0m"

    read sendgrid_api_key
    declare -p sendgrid_api_key >> $HOME_DIR/.secret/config/keys

    echo -e "\e[33mThanks your inputs has been taken \e[0m"

# make the secret file executable

source $HOME_DIR/.secret/config/keys

function sendmail {
#  get the secret variables
test ! -f "./$HOME_DIR/.secret/config/keys" || source ${_}

SENDGRID_API_KEY=${sendgrid_api_key}
EMAIL_TO=${email_to}
NAME=${name}
FROM_EMAIL=${email_from}
SUBJECT=${subject}

    #-------parameter passed as message------------------
    MESSAGE=$1
    #-------sample send email curl command---------------
    REQUEST_DATA='{ "personalizations":
    [{
        "to": [{ "email":"'"$EMAIL_TO"'" }],
        "subject": "'"$SUBJECT"'"
    }],
    "from":{
        "email": "'"$FROM_EMAIL"'",
        "name": "'"$NAME"'"
    },
    "content":[{
        "type": "text/plain",
        "value": "'"$MESSAGE"'"
    }]
    }';
    #--------Sends the email----------------------------
    curl -X "POST" "https://api.sendgrid.com/v3/mail/send" \
         -H "Authorization:Bearer $SENDGRID_API_KEY" \
         -H "Content-Type: application/json" \
         -d "$REQUEST_DATA"
}
    #------Send introductory email notification with IP Address----------------------
    IP=$(hostname -i)
    NAME=$(hostname)
    MESSAGE="Node auditor block height script notification has been successfully configured for $IP on $NAME."
    sendmail "$MESSAGE" 
    echo -e "
\e[32m#############################
#CHECK YOUR EMAIL TO CONFIRM THE SETUP#
#############################\e[0m
"

cat <<'EOT' > blockheight.sh
#!/bin/bash
# Author : Bashiru 
# Editor : Michael
# Modified : 19/5/2022 MM/DD/YYYY
# Description : This script checks the current node block height and sends a notification if it falls by a number of blocks

#---------Clear console---------
clear
test ! -f "./$HOME_DIR/.secret/config/keys" || source ${_}
user=${user}
HOME_DIR=$(getent passwd "$user" | cut -d: -f6)
cd $HOME_DIR
echo

#------------get the secret variables---------------------
test ! -f "./$HOME_DIR/.secret/config/keys" || source ${_}

SENDGRID_API_KEY=${sendgrid_api_key}
EMAIL_TO=${email_to}
NAME=${name}
FROM_EMAIL=${email_from}
SUBJECT=${subject}
NUMBER_OF_BLOCKS=${numberofblocks}

#-------- Send email notification--------------------------
function sendmail {
    #-------parameter passed as message------------------
    MESSAGE=$1

    #-------sample send email curl command---------------
    REQUEST_DATA='{ "personalizations":
    [{
        "to": [{ "email":"'"$EMAIL_TO"'" }],
        "subject": "'"$SUBJECT"'"
    }],
    "from":{
        "email": "'"$FROM_EMAIL"'",
        "name": "'"$NAME"'"
    },
    "content":[{
        "type": "text/plain",
        "value": "'"$MESSAGE"'"
    }]
    }';

    #--------Sends the email----------------------------
    curl -X "POST" "https://api.sendgrid.com/v3/mail/send" \
         -H "Authorization:Bearer $SENDGRID_API_KEY" \
         -H "Content-Type: application/json" \
         -d "$REQUEST_DATA"
}

#--------- Function to compute block_height----------------------------
function compute_block_height {

    #-----Find out the block height of the mainnet-----------
    mainheight=$(curl -sSm5 "https://supply.research.pokt.network:8192/height")

    #-----Confirm excecution of the above command by printing block height-----------
    if [ "$?" -eq 0 ]; then 
        echo "Mainnet block height is : $mainheight"
    else
        echo "Could not retrieve mainnet block height ensure you have an internet connection"
    fi 

    #------check current node block height and output to json-----------------------
            sudo -i -u pocket bash << 'EOF'
    pocket query height >json
EOF

    #------function to extract height from json file-------------------------------
    function readJson {

        #------ returns the linux distribution---------------
        UNAMESTR=$(uname)
        if [[ "$UNAMESTR" == 'Linux' ]]; then
            SED_EXTENDED='-r'
        elif [[ "$UNAMESTR" == 'Darwin' ]]; then
            SED_EXTENDED='-E'
        fi;

        #------ grep -m 1 "\"${2}\"" ${1} --- filter strings containing ${2} from file ${1}
        #------ sed ${SED_EXTENDED} 's/^ *//;s/.*: *"//;s/",?//' takes a regular expression extension to filter stream
        VALUE=$(grep -m 1 "\"${2}\"" ${1} | sed ${SED_EXTENDED} 's/^ *//;s/.*: *"//;s/",?//')
        if [ ! "$VALUE" ]; then
            echo "Error : Cannot find \"${2}\" in ${1}" >&2;
            exit 1;
        else 
            Blockheight=$(echo "$VALUE" | tr -dc '0-9');
            echo $Blockheight
        fi;
    }

    #------ Read Json file and filter height--------
    height=$(readJson json height || exit 1)

    #------ Confirm the previous command executed successfully--------
    if [ "$?" -eq 0 ]; then 
        echo "Current node block height : $height"
    else 
        echo "Could not retrieve node block height"
        exit 1
    fi

    #------- Find the difference in block height between current node and remote
    block_height_difference=$(($mainheight - $height))
    if [ $block_height_difference -gt 0 ]; then
        echo "$block_height_difference block | blocks behind"
    else
        echo "0 block behind"
    fi

    #----- Check to see if it's greater than the set threshold

    block_threshold="$NUMBER_OF_BLOCKS"
    if (("$block_height_difference" >= "$block_threshold")); then

    #------Send email notification----------------------
    IP=$(hostname -i)
    NAME=$(hostname)
    MESSAGE="Node with hostname $NAME on $IP is behind the main net block height by $block_height_difference blocks.The main net block height is $mainheight"
    sendmail "$MESSAGE"
    else 
    echo "Threshold not hit"
    fi
}


#--------Init the compute_block_height service------------------------
function initService {


    #------------get the secret variables---------------------
    test ! -f "./$HOME_DIR/.secret/config/keys" || source ${_}

    SENDGRID_API_KEY=${sendgrid_api_key}
    EMAIL_TO=${email_to}
    NAME=${name}
    FROM_EMAIL=${email_from}
    SUBJECT=${subject}
    NUMBER_OF_BLOCKS=${numberofblocks}

    if  [ "$SENDGRID_API_KEY" != "" ]&& [ "$EMAIL_TO" != "" ] && [ "$FROM_EMAIL" != "" ]  && [ "$NAME" != "" ] && [ "$SUBJECT" != "" ] && [ "$NUMBER_OF_BLOCKS" != "" ]; then 

#------Compute the block height-----------------------------------
    compute_block_height
    else

#-------Set up notification first-------------------------------------
    echo -e "\e[31mCould not configure script input try again\e[0m"
    exit 1 
    fi 

}

initService

EOT

cd $HOME_DIR

chmod +x blockheight.sh


export BLOCKHEIGHT_SERVICE=$(
    cat <<EOF
[Unit]
Description=Block height service
[Service]
User=pocket
Group=sudo
ExecStart=$HOME_DIR/blockheight.sh 
EOF
)
cd /etc/systemd/system/ && envsubst <<<"$BLOCKHEIGHT_SERVICE" >"blockheight.service"
#============================Enable service================================================================
systemctl daemon-reload
systemctl enable blockheight.service
systemctl start blockheight.service

#============================create systemd timer==========================================================
export BLOCKHEIGHT_TIMER=$(
    cat <<EOF
[Unit]
Description=To monitor the block height of the node
[Timer]
Unit=blockheight.service
OnBootSec=5min
OnUnitActiveSec=10min
[Install]
WantedBy=timers.target
EOF
)
cd /etc/systemd/system/ && envsubst <<<"$BLOCKHEIGHT_TIMER" >"blockheight.timer"

#============================Enable timer================================================================
systemctl daemon-reload
systemctl enable blockheight.timer
systemctl start blockheight.timer

echo -e "
\e[32m#############################
#YOUR BLOCKHEIGHT SCRIPT HAS BEEN SETUP SUCCESSFULLY#
#NOTE! IGNORE WARNINGS ABOVE FOR SYSTEMD#
#############################\e[0m
"

