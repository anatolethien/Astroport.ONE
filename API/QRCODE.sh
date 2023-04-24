################################################################################
# Author: Fred (support@qo-op.com)
# Version: 0.1
# License: AGPL-3.0 (https://choosealicense.com/licenses/agpl-3.0/)
################################################################################
################################################################################
## API: QRCODE - ANY/MULTI KEY OPERATIONS
################################################################################
MY_PATH="`dirname \"$0\"`"              # relative
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"  # absolutized and normalized
. "${MY_PATH}/../tools/my.sh"

start=`date +%s`

echo "PORT=$1 THAT=$2 AND=$3 THIS=$4  APPNAME=$5 WHAT=$6 OBJ=$7 VAL=$8 MOATS=$9 COOKIE=$10"
PORT=$1 THAT=$2 AND=$3 THIS=$4  APPNAME=$5 WHAT=$6 OBJ=$7 VAL=$8 MOATS=$9 COOKIE=$10
### transfer variables according to script
QRCODE=$THAT
TYPE=$WHAT

echo "COOKIE : $COOKIE"

HTTPCORS="HTTP/1.1 200 OK
Access-Control-Allow-Origin: ${myASTROPORT}
Access-Control-Allow-Credentials: true
Access-Control-Allow-Methods: GET
Server: Astroport.ONE
Content-Type: text/html; charset=UTF-8

"
function urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

## GET TW
mkdir -p ~/.zen/tmp/${MOATS}/

################################################################################
## QRCODE IS HTTP LINK
###############################################################################
if [[ ${QRCODE:0:4} == "http" ]]; then
    ## THIS IS A WEB LINK
    sed "s~_TWLINK_~${QRCODE}/~g" ${MY_PATH}/../templates/index.302  > ~/.zen/tmp/${MOATS}/index.redirect
    sed -i "s~Set-Cookie*~Set-Cookie: $COOKIE~" ~/.zen/tmp/${MOATS}/index.redirect
    echo "url='"${QRCODE}"'" >> ~/.zen/tmp/${MOATS}/index.redirect
    (
    cat ~/.zen/tmp/${MOATS}/index.redirect | nc -l -p ${PORT} -q 1 > /dev/null 2>&1
    echo "BLURP $PORT" && rm -Rf ~/.zen/tmp/${MOATS}
    ) &
    exit 0

fi

################################################################################
## QRCODE="station" : REFRESH STATION & OPEN G1PalPay INTERFACE
###############################################################################
if [[ ${QRCODE} == "station" ]]; then

    # Keep 2nd try of the day
    [[ ! -s ~/.zen/tmp/_ISTATION ]] \
        && mv ~/.zen/tmp/ISTATION ~/.zen/tmp/_ISTATION \
        || cp ~/.zen/tmp/_ISTATION ~/.zen/tmp/ISTATION

    if [[ ! -s ~/.zen/tmp/ISTATION ]]; then
        ## GENERATE PLAYER G1 TO ZEN ACCOUNTING
        ISTATION=$($MY_PATH/../tools/make_image_ipfs_index_carousel.sh | tail -n 1)
        echo $ISTATION > ~/.zen/tmp/ISTATION ## STATION G1WALLET CAROUSEL
    else
        ISTATION=$(cat ~/.zen/tmp/ISTATION)
    fi
        ## SHOW G1PALPAY FRONT (IFRAME)
        sed "s~_STATION_~${myIPFS}${ISTATION}/~g" $MY_PATH/../www/G1PalPay/index.html > ~/.zen/tmp/${MOATS}/index.htm
        [[ ! $isLAN ]] && sed -i "s~MENU~DEMO~g" ~/.zen/tmp/${MOATS}/index.htm
        sed -i "s~http://127.0.0.1:8080~${myIPFS}~g" ~/.zen/tmp/${MOATS}/index.htm
        sed -i "s~http://astroport.localhost:1234~${myASTROPORT}~g" ~/.zen/tmp/${MOATS}/index.htm

        WSTATION="/ipfs/$(ipfs add -q ~/.zen/tmp/${MOATS}/index.htm)"
        echo $WSTATION > ~/.zen/tmp/WSTATION
        end=`date +%s`
        echo "NEW WSTATION ${myIPFS}${WSTATION} Execution time was "`expr $end - $start` seconds.
    ## SEND TO WSTATION PAGE
    sed "s~_TWLINK_~${myIPFS}${WSTATION}/~g" ${MY_PATH}/../templates/index.302  > ~/.zen/tmp/${MOATS}/index.redirect
    sed -i "s~Set-Cookie*~Set-Cookie: $COOKIE~" ~/.zen/tmp/${MOATS}/index.redirect
    echo "url='"${myIPFS}${WSTATION}"'" >> ~/.zen/tmp/${MOATS}/index.redirect
    (
    cat ~/.zen/tmp/${MOATS}/index.redirect | nc -l -p ${PORT} -q 1 > /dev/null 2>&1
    echo "BLURP $PORT" && rm -Rf ~/.zen/tmp/${MOATS}
    ) &
    exit 0
fi

################################################################################
## QRCODE = PGP ENCRYPTED STRING
# /?qrcode=-----BEGIN%20PGP%20MESSAGE-----~~jA0ECQMC5iqIY7XLnGn_0koBJB5S2Sy1p%2FHr8CKFgWdZ9_j%2Fb2qdOznICGvqGCXY~7Flw6YtiabngvY6biq%2F0vpiFL8t8BSbMZe0GLBU90EMBrhzEiyPnh__bzQ%3D%3D~%3D9UIj~-----END%20PGP%20MESSAGE-----~
# &pass=coucou&history/read/pay/login=(1|email)&g1pub=_DESTINATAIRE_
################################################################################
if [[ ${QRCODE:0:5} == "~~~~~" ]]; then
   echo ${QRCODE}
   PASS=$(urldecode ${THIS})
   echo "## THIS IS A PGP ENCRYPTED QRCODE LOOK - PASS ${PASS} - $APPNAME"

    if [[ ${PASS} != "" ]]; then
        echo "WHAT=${WHAT} VAL=${VAL}"

        ## Recreate GPG aes file
        urldecode ${QRCODE} | tr '_' '+' | tr '-' '\n' | tr '~' '-'  > ~/.zen/tmp/${MOATS}/disco.aes
        sed -i '$ d' ~/.zen/tmp/${MOATS}/disco.aes
        # Decoding
        echo "cat ~/.zen/tmp/${MOATS}/disco.aes | gpg -d --passphrase "${PASS}" --batch"
        cat ~/.zen/tmp/${MOATS}/disco.aes | gpg -d --passphrase "${PASS}" --batch > ~/.zen/tmp/${MOATS}/decoded

        # cat ~/.zen/tmp/${MOATS}/disco
        ## FORMAT IS "/?salt=${USALT}&pepper=${UPEPPER}"
        DISCO=$(cat ~/.zen/tmp/${MOATS}/decoded  | cut -d '?' -f2)
        arr=(${DISCO//[=&]/ })
        s=$(urldecode ${arr[0]} | xargs)
        salt=$(urldecode ${arr[1]} | xargs)
        p=$(urldecode ${arr[2]} | xargs)
        pepper=$(urldecode ${arr[3]} | xargs)

       echo "$HTTPCORS" > ~/.zen/tmp/${MOATS}/disco

        if [[ ${salt} != "" && ${pepper} != "" ]]; then
            ${MY_PATH}/../tools/keygen -t duniter -o ~/.zen/tmp/${MOATS}/secret.key  "$salt" "$pepper"
            G1PUB=$(cat ~/.zen/tmp/${MOATS}/secret.key | grep 'pub:' | cut -d ' ' -f 2)

            echo "${MY_PATH}/../tools/jaklis/jaklis.py balance -p ${G1PUB}"
            ${MY_PATH}/../tools/COINScheck.sh ${G1PUB} > ~/.zen/tmp/${G1PUB}.curcoin
            cat ~/.zen/tmp/${G1PUB}.curcoin
            CURCOINS=$(cat ~/.zen/tmp/${G1PUB}.curcoin | tail -n 1)
            echo "CURRENT KEY : $CURCOINS G1"

            [[ ${WHAT} == "" ]] &&  echo "<br> Missing amount <br>" >> ~/.zen/tmp/${MOATS}/disco
            [[ ${VAL} == "" || ${VAL} == "undefined" ]] &&  echo "<br> Missing Destination PublicKey <br>" >> ~/.zen/tmp/${MOATS}/disco

            ## GET DESTINATION ACCOUNT AMOUNT
            DESTM=$(${MY_PATH}/../tools/COINScheck.sh ${VAL} | tail -n 1)

            if [[ $APPNAME == "pay" ]]; then

                 if [[ ${WHAT} != "" && ${VAL} != "" && ${CURCOINS} != "null" && ${CURCOINS} != "" &&  ${CURCOINS} -gt ${WHAT} ]]; then
                    ## COMMAND A PAYMENT
                        if [[ $WHAT =~ ^[0-9]+$ ]]; then

                            echo "${MY_PATH}/../tools/jaklis/jaklis.py -k ~/.zen/tmp/${MOATS}/secret.key pay -a ${WHAT} -p ${VAL} -c 'ASTRO:Bro' -m"
                            ${MY_PATH}/../tools/timeout.sh -t 5 \
                            ${MY_PATH}/../tools/jaklis/jaklis.py -k ~/.zen/tmp/${MOATS}/secret.key pay -a ${WHAT} -p ${VAL} -c "G1PASS:${MOATS}" -m 2>&1 >> ~/.zen/tmp/${MOATS}/disco

                            #################################### SYSTEM IS NOT DUNITER OVER POOL RESISTANT
                            if [ $? == 0 ]; then

                                ## TODO : MEMORIZE TX TO VERIFY ASTRO/DUNITER SYNC
                                COINSFILE="$HOME/.zen/tmp/coucou/${G1PUB}.COINS"
                                DESTFILE="$HOME/.zen/tmp/coucou/${VAL}.COINS"

                                CUR=$(cat ${COINSFILE})
                                [[ ${CUR} != "" && ${CUR} != "null" ]] \
                                    && echo $((CUR-WHAT)) > ${COINSFILE} \
                                    || echo ${WHAT} > ${COINSFILE}
                                cat ${COINSFILE}

                                DES=$(cat ${DESTFILE})
                                [[ ${DES} != "" && ${DES} != "null" ]] \
                                    && echo $((DES+WHAT)) > ${DESTFILE} \
                                    || echo ${WHAT} > ${DESTFILE}
                                cat ${DESTFILE}

                                echo "<h1>OPERATION</h1> <h3>$G1PUB <br> $CUR - ${WHAT}</h3> <h3>${VAL} <br> $DES + ${WHAT} </h3><h2>OK</h2>" >> ~/.zen/tmp/${MOATS}/disco

                            fi
                        fi

                else

                     echo "<h2>${WHAT} ${VAL} ${CURCOINS} PROBLEM</h2>" >> ~/.zen/tmp/${MOATS}/disco
                fi

            fi

            if [[ $APPNAME == "history" || $APPNAME == "read" ]]; then

                ## history & read ## CANNOT USE jaklis CLI formated output (JSON output)
                echo "$HTTPCORS" > ~/.zen/tmp/${MOATS}/disco
                sed -i "s~text/html~application/json~g"  ~/.zen/tmp/${MOATS}/disco
                # cp ~/.zen/tmp/${MOATS}/secret.key ~/.zen/tmp/
                echo "${MY_PATH}/../tools/jaklis/jaklis.py -k ~/.zen/tmp/secret.key $APPNAME -j"
                ${MY_PATH}/../tools/jaklis/jaklis.py -k ~/.zen/tmp/${MOATS}/secret.key $APPNAME -j >> ~/.zen/tmp/${MOATS}/disco

            fi

            if [[ $APPNAME == "balance" ]]; then

                ## history & read
                # cp ~/.zen/tmp/${MOATS}/secret.key ~/.zen/tmp/
                qrencode -s 6 -o "${HOME}/.zen/tmp/${MOATS}/disco.qr.png" "$G1PUB"
                QRURL=${myIPFS}/ipfs/$(ipfs add -q ~/.zen/tmp/${MOATS}/disco.qr.png)
                ONVADIRE="<h1> ~ ${CURCOINS} Ğ1</h1>${G1PUB}<br><br><img src=${QRURL} />"
                echo "${ONVADIRE}" >> ~/.zen/tmp/${MOATS}/disco

            fi

            if [[ $APPNAME == "friend" ]]; then
                ## Send ॐ★ॐ
                ${MY_PATH}/../tools/jaklis/jaklis.py -k ~/.zen/tmp/${MOATS}/secret.key stars -p ${VAL} -n ${WHAT} >> ~/.zen/tmp/${MOATS}/disco

            fi

            if [[ $APPNAME == "login" ]]; then

                PLAYER=${WHAT}
                ISTHERE=$(ipfs key list -l | grep -w ${PLAYER} | cut -d ' ' -f1)
                echo "IS THERE ? $ISTHERE"
                [[ ${ISTHERE} == "" ]] \
                && ${MY_PATH}/../tools/keygen -t ipfs -o ~/.zen/tmp/${MOATS}/secret.ipns  "$salt" "$pepper" \
                && ipfs key import ${PLAYER} -f pem-pkcs8-cleartext ~/.zen/tmp/${MOATS}/secret.ipns \
                && ASTRONAUTENS=$(ipfs key list -l | grep -w ${PLAYER} | cut -d ' ' -f1) \
                || ASTRONAUTENS=${ISTHERE}

                ( ## 1 HOUR SESSION
                    [[ ${ISTHERE} == "" ]] && echo "SESSION START" && sleep 3600 && echo "${PLAYER} SESSION OVER" && ipfs key rm ${PLAYER}
                ) &

                REPLACE=${myIPFS}/ipns/${ASTRONAUTENS}
                echo "${PLAYER} LOGIN - TW : ${REPLACE}"

                sed "s~_TWLINK_~${REPLACE}~g" ~/.zen/Astroport.ONE/templates/index.302  > ~/.zen/tmp/${MOATS}.index.redirect
                echo "url='"${REPLACE}"'" >> ~/.zen/tmp/${MOATS}.index.redirect
                (
                    cat ~/.zen/tmp/${MOATS}.index.redirect | nc -l -p ${PORT} -q 1 > /dev/null 2>&1
                    echo "BLURP " && rm -Rf ~/.zen/tmp/${MOATS} && rm ~/.zen/tmp/coucou/${MOATS}*
                ) &
                exit 0

            fi

        else

            echo "<br><h1>${PASS} : MAUVAIS PASS</h1>" >> ~/.zen/tmp/${MOATS}/disco
            echo "<br><img src='http://127.0.0.1:8080/ipfs/QmVnQ3GkQjNeXw9qM7Fb1TFzwwxqRMqD9AQyHfgx47rNdQ/your-own-data-cloud.svg' />" >> ~/.zen/tmp/${MOATS}/disco
        fi

    else

        echo "<br>DATA MISSING" >> ~/.zen/tmp/${MOATS}/disco
    fi

    (
    cat ~/.zen/tmp/${MOATS}/disco | nc -l -p ${PORT} -q 1 > /dev/null 2>&1
    echo "BLURP $PORT" && rm -Rf ~/.zen/tmp/${MOATS}
    ) &
    exit 0

fi

################################################################################
## QRCODE = G1* : MODE G1VOEU : RETURN WISHNS - IPNS App link - or direct tw tag selected json
# ~/?qrcode=G1Tag&tw=_IPNS_PLAYER_(&json)
################################################################################
if [[ ${QRCODE:0:2} == "G1" && ${AND} == "tw" ]]; then

    VOEU=${QRCODE:2} ## "G1G1Voeu" => "G1Voeu"
    # THIS is TW IPNS
    ASTROPATH=$(grep -r ${THIS} ~/.zen/game/players/*/ipfs/moa | tail -n 1 | cut -d ':' -f 1 | rev | cut -d '/' -f 2- | rev  2>/dev/null)
    echo "ASTROPATH=${ASTROPATH}"

    INDEX=${ASTROPATH}/index.html
    echo $INDEX

    if [[ -s  ${INDEX} ]]; then

        if [[ ${APPNAME} == "json" ]]; then
        ##############################################
            echo "DIRECT Tag = ${VOEU} OUTPUT"
            ## DIRECT JSON OUTPUT
            tiddlywiki --load ${INDEX} --output ~/.zen/tmp/${MOATS} \
            --render '.' "g1voeu.json" 'text/plain' '$:/core/templates/exporters/JsonFile' 'exportFilter' '[tag['${VOEU}']]'

            echo "$HTTPCORS" > ~/.zen/tmp/${MOATS}/index.redirect
            sed -i "s~text/html~application/json~g"  ~/.zen/tmp/${MOATS}/index.redirect
            cat ~/.zen/tmp/${MOATS}/g1voeu.json >> ~/.zen/tmp/${MOATS}/index.redirect
            (
            cat ~/.zen/tmp/${MOATS}/index.redirect | nc -l -p ${PORT} -q 1 > /dev/null 2>&1
            echo "BLURP $PORT" && rm -Rf ~/.zen/tmp/${MOATS}
            ) &
            exit 0

        fi
        ##############################################
        echo "## IPNS G1Voeu APP REDIRECT"
        tiddlywiki --load ${INDEX} --output ~/.zen/tmp --render '.' "${MOATS}.g1voeu.json" 'text/plain' '$:/core/templates/exporters/JsonFile' 'exportFilter' '[tag[G1Voeu]]'
        cat ~/.zen/tmp/${MOATS}.g1voeu.json | jq -r '.[].wish' > ~/.zen/tmp/${MOATS}.g1wishes.txt
        cat ~/.zen/tmp/${MOATS}.g1wishes.txt
        while read WISH
        do
            [[ ${WISH} == "" || ${WISH} == "null" ]] && echo "BLURP. EMPTY WISH" && continue
            WISHNAME=$(cat ~/.zen/tmp/${MOATS}.g1voeu.json | jq .[] | jq -r 'select(.wish=="'${WISH}'") | .title')
            WISHNS=$(cat ~/.zen/tmp/${MOATS}.g1voeu.json | jq .[] | jq -r 'select(.wish=="'${WISH}'") | .wishns')
            echo "${WISHNAME} : ${WISHNS} "
            [[ "G1${WISHNAME}" == "$VOEU" ]] \
            && echo "FOUND" \
            && LINK=${myIPFS}${WISHNS} \
            && break

        done < ~/.zen/tmp/${MOATS}.g1wishes.txt

    fi

    ## REDIRECT TO G1VOEU IPNS ADDRESS
    [[ $LINK == "" ]] && LINK="$myIPFS/ipfs/QmWUZr62SpriLPuqauMbMxvw971qnu741hV8EhrHmKF2Y4" ## 404 LOST IN CYBERSPACE
    echo "#>>> DISPLAY WISHNS >>>> # $VOEU : $LINK"
    sed "s~_TWLINK_~${LINK}~g" ${MY_PATH}/../templates/index.302  > ~/.zen/tmp/${MOATS}/index.redirect
    sed -i "s~Set-Cookie*~Set-Cookie: $COOKIE~" ~/.zen/tmp/${MOATS}/index.redirect
    echo "url='"${LINK}"'" >> ~/.zen/tmp/${MOATS}/index.redirect
    (
    cat ~/.zen/tmp/${MOATS}/index.redirect | nc -l -p ${PORT} -q 1 > /dev/null 2>&1
    echo "BLURP $PORT" && rm -Rf ~/.zen/tmp/${MOATS}
    ) &
    exit 0
fi

################################################################################
## QRCODE = IPNS or G1PUB ? Can be ASTRONAUTENS or G1PUB format
################################################################################
## QRCODE IS IPNS FORMAT : CHANGE .current AND MAKE G1BILLETS
ASTROPATH=$(grep -r $QRCODE  ~/.zen/game/players/*/ipfs/moa | tail -n 1 | cut -d ':' -f 1 | rev | cut -d '/' -f 2- | rev  2>/dev/null)
if [[ ${ASTROPATH} != "" && $APPNAME == "" ]]; then

    PLAYER=$(echo ${ASTROPATH} | rev | cut -d '/' -f 3 | rev)

    rm ~/.zen/game/players/.current
    ln -s ~/.zen/game/players/${PLAYER} ~/.zen/game/players/.current
    echo "LINKING ${PLAYER} to .current"
    #### SELECT PARRAIN "G1PalPay"

    echo "#>>>>>>>>>>>> # REDIRECT TO CREATE G1BILLETS"
    sed "s~_TWLINK_~${myG1BILLET}?montant=0\&style=${PLAYER}~g" ${MY_PATH}/../templates/index.302  > ~/.zen/tmp/${MOATS}/index.redirect
    sed -i "s~Set-Cookie*~Set-Cookie: $COOKIE~" ~/.zen/tmp/${MOATS}/index.redirect
    echo "url='"${myG1BILLET}"?montant=0\&style=${PLAYER}'" >> ~/.zen/tmp/${MOATS}/index.redirect
    (
    cat ~/.zen/tmp/${MOATS}/index.redirect | nc -l -p ${PORT} -q 1 > /dev/null 2>&1
    echo "BLURP $PORT" && rm -Rf ~/.zen/tmp/${MOATS}
    ) &
    exit 0

else

    echo "NOT ON BOARD"
    echo "What is this $QRCODE ?"
    echo "AND=$3 THIS=$4  APPNAME=$5 WHAT=$6 OBJ=$7 VAL=$8 MOATS=$9 COOKIE=$10"

fi

################################################################################
## TEST G1 TYPE ( should convert to ipfs )
ASTROTOIPFS=$(${MY_PATH}/../tools/g1_to_ipfs.py ${QRCODE} 2>/dev/null)
        [[ ! ${ASTROTOIPFS} ]] \
        && echo "INVALID QRCODE : ${QRCODE}" \
        && (echo "$HTTPCORS ERROR - INVALID QRCODE : ${QRCODE}"  | nc -l -p ${PORT} -q 1 > /dev/null 2>&1 &) \
        && exit 1
################################################################################
echo "############################################################################"
echo ">>> ${QRCODE} g1_to_ipfs $ASTROTOIPFS"

    ## GET VISITOR G1 WALLET AMOUNT : VISITORCOINS
    echo "COINScheck : ${MY_PATH}/../tools/jaklis/jaklis.py balance -p ${QRCODE}"
    VISITORCOINS=$(${MY_PATH}/../tools/COINScheck.sh ${QRCODE} | tail -n 1)
    COINSFILE=$HOME/.zen/tmp/coucou/${QRCODE}.COINS

###########################################################
## SEARCH IF G1PUB IS IN PLAYERS OTHERWISE CHOOSE CURRENT SECRET
##########################################################
MYPLAYERKEY=$(grep ${QRCODE} ~/.zen/game/players/*/secret.dunikey | cut -d ':' -f 1)
[[ ${MYPLAYERKEY} == "" ]] && MYPLAYERKEY="$HOME/.zen/game/players/.current/secret.dunikey"
echo "SELECTED STATION KEY : $(cat ${MYPLAYERKEY} | grep 'pub:')"
echo

## AUTOGRAPH FROM CURRENT
###########################################
CURPLAYER=$(cat ~/.zen/game/players/.current/.player)
CURG1=$(cat ~/.zen/game/players/.current/.g1pub)
echo "${MY_PATH}/../tools/jaklis/jaklis.py balance -p ${CURG1}"
CURCOINS=$(${MY_PATH}/../tools/COINScheck.sh ${CURG1} | tail -n 1)
echo "AUTOGRAPH $CURPLAYER : $CURCOINS G1"

## WALLET VIERGE
###########################################
if [[ $VISITORCOINS == "null" || $CURCOINS == "null" ]]; then

    echo "NULL. PLEASE CHARGE. OR CHECK STATION"

    echo "${HTTPCORS}" > ~/.zen/tmp/${MOATS}/index.redirect
    echo "<h1>SCAN $VISITORCOINS Ǧ1 (CURRENT $CURCOINS Ǧ1)</h1>
    ... Any problem? Contact <a href='mailto:support@qo-op.com'>support</a>
    ($myHOST)"  >> ~/.zen/tmp/${MOATS}/index.redirect
    (
    cat ~/.zen/tmp/${MOATS}/index.redirect | nc -l -p ${PORT} -q 1 > /dev/null 2>&1
    echo "BLURP $PORT" && rm -Rf ~/.zen/tmp/${MOATS}
    ) &
    exit 0

fi

# DETECT TO REWARD IN REGARD TO WALLET EVOLUTION
########################################### G1 PRICE : null 1 + gchange 10 + cesium 50
if [[ ${CURG1} == ${QRCODE} ]]; then

    echo "${HTTPCORS}" > ~/.zen/tmp/${MOATS}/index.redirect
    echo "<h1>$CURPLAYER WALLET : $CURCOINS Ǧ1</h1>"  >> ~/.zen/tmp/${MOATS}/index.redirect
    (
    cat ~/.zen/tmp/${MOATS}/index.redirect | nc -l -p ${PORT} -q 1 > /dev/null 2>&1
    echo "BLURP $PORT" && rm -Rf ~/.zen/tmp/${MOATS}
    ) &
    exit 0

else
# ANY VISITOR WALLET
###########################################

    ## EMPTY WALLET ? PREPARE PALPE WELCOME
    if [[ $VISITORCOINS == "null" ]]; then
        # CADEAU DE 10 JUNE (Si le .current en a plus que 100)
        PALPE=1
        echo "PALPE=1"
    else
        PALPE=0
    fi

        echo "VISITEUR POSSEDE ${VISITORCOINS} G1"

        ## GET G1 WALLET HISTORY
        if [[ ${VISITORCOINS} != "null" && ${VISITORCOINS} -gt 0 ]]; then

            [[ ! -s ~/.zen/tmp/coucou/${QRCODE}.g1history.json ]] \
            && ${MY_PATH}/../tools/timeout.sh -t 20 $MY_PATH/../tools/jaklis/jaklis.py history -p ${QRCODE} -j > ~/.zen/tmp/coucou/${QRCODE}.g1history.json

            echo "${HTTPCORS}" > ~/.zen/tmp/${MOATS}/index.redirect
            echo "<h1>Solde $VISITORCOINS Ǧ1</h1>" >> ~/.zen/tmp/${MOATS}/index.redirect
            echo "<h2><a target=_blank href="$myIPFS/ipfs/$(ipfs add -q ~/.zen/tmp/coucou/${QRCODE}.g1history.json)">HISTORIQUE ${QRCODE}</a></h2>"  >> ~/.zen/tmp/${MOATS}/index.redirect
            (
            cat ~/.zen/tmp/${MOATS}/index.redirect | nc -l -p ${PORT} -q 1 > /dev/null 2>&1
            echo "BLURP $PORT" && rm -Rf ~/.zen/tmp/${MOATS}
            ) &
            exit 0

        fi

        ## SCAN GCHANGE +
        [[ ! -s ~/.zen/tmp/coucou/${QRCODE}.gchange.json ]] \
        && ${MY_PATH}/../tools/timeout.sh -t 20 curl -s ${myDATA}/user/profile/${QRCODE} > ~/.zen/tmp/coucou/${QRCODE}.gchange.json &

        GFOUND=$(cat ~/.zen/tmp/coucou/${QRCODE}.gchange.json | jq -r '.found')
        echo "FOUND IN GCHANGE+ ? $GFOUND"

        if [[ $GFOUND == "false" ]]; then
            echo "NO GCHANGE YET. REDIRECT"
            sed "s~_TWLINK_~${myGCHANGE}~g" ${MY_PATH}/../templates/index.302  > ~/.zen/tmp/${MOATS}/index.redirect
            echo "url='"${myGCHANGE}"'" >> ~/.zen/tmp/${MOATS}/index.redirect
            sed -i "s~Set-Cookie*~Set-Cookie: $COOKIE~" ~/.zen/tmp/${MOATS}/index.redirect
            ( cat ~/.zen/tmp/${MOATS}/index.redirect | nc -l -p ${PORT} -q 1 > /dev/null 2>&1) &
            exit 0
        else
            [[ $VISITORCOINS == "null" ]] && PALPE=10 \
            && echo "~/.zen/tmp/coucou/${QRCODE}.gchange.json CHECK : PALPE=10"
        fi

        ## SCAN CESIUM +
        [[ ! -s ~/.zen/tmp/coucou/${QRCODE}.gplus.json ]] \
        && ${MY_PATH}/../tools/timeout.sh -t 10 curl -s ${myCESIUM}/user/profile/${QRCODE} > ~/.zen/tmp/coucou/${QRCODE}.gplus.json 2>/dev/null &

        GCFOUND=$(cat ~/.zen/tmp/coucou/${QRCODE}.gplus.json | jq -r '.found')
        echo "FOUND IN CESIUM+ ? $GCFOUND"

        if [[ $GCFOUND == "false" ]]; then
            echo "PAS DE COMPTE CESIUM POUR CETTE CLEF GCHANGE"
            sed "s~_TWLINK_~https://demo.cesium.app/#/app/wot/$QRCODE/~g" ${MY_PATH}/../templates/index.302  > ~/.zen/tmp/${MOATS}/index.redirect
            echo "url='"${myASTRONEF}"'" >> ~/.zen/tmp/${MOATS}/index.redirect
            sed -i "s~Set-Cookie*~Set-Cookie: $COOKIE~" ~/.zen/tmp/${MOATS}/index.redirect
            ( cat ~/.zen/tmp/${MOATS}/index.redirect | nc -l -p ${PORT} -q 1 > /dev/null 2>&1) &
            exit 0
        else
            [[ $VISITORCOINS == "null" ]] && PALPE=50 \
            && echo "~/.zen/tmp/coucou/${QRCODE}.gplus.json CHECK : PALPE=50"
        fi

        ## CHECK IF GCHANGE IS LINKED TO "A DECLARED CESIUM"
        CPLUS=$(cat ~/.zen/tmp/coucou/${QRCODE}.gchange.json | jq -r '._source.pubkey' 2>/dev/null)
        echo "CPLUS=$CPLUS"
        ## SCAN GPUB CESIUM +

        ##### DO WE HAVE A DIFFERENT KEY LINKED TO GCHANGE ??
        if [[ $CPLUS != "" && $CPLUS != 'null' && $CPLUS != $QRCODE ]]; then

            ## SCAN FOR CPLUS CESIUM + ACCOUNT
            [[ ! -s ~/.zen/tmp/coucou/${QRCODE}.cplus.json ]] \
            && ${MY_PATH}/../tools/timeout.sh -t 10 curl -s ${myCESIUM}/user/profile/${CPLUS} > ~/.zen/tmp/coucou/${QRCODE}.cplus.json 2>/dev/null &

            CCFOUND=$(cat ~/.zen/tmp/coucou/${QRCODE}.cplus.json | jq -r '.found')

            if [[ $CCFOUND == "false" ]]; then
                echo "AUCUN CCPLUS : MEMBRE LIE"
                sed "s~_TWLINK_~https://monnaie-libre.fr~g" ${MY_PATH}/../templates/index.302  > ~/.zen/tmp/${MOATS}/index.redirect
                sed -i "s~Set-Cookie*~Set-Cookie: $COOKIE~" ~/.zen/tmp/${MOATS}/index.redirect
                ( cat ~/.zen/tmp/${MOATS}/index.redirect | nc -l -p ${PORT} -q 1 > /dev/null 2>&1) &
                exit 0
            else
                ## MESSAGE TO LINKED CESIUM WALLET
                $MY_PATH/../tools/jaklis/jaklis.py -n $myCESIUM -k ${MYPLAYERKEY} send -d "${CPLUS}" -t "COUCOU" \
                -m "VOTRE PORTEFEUILLE ${QRCODE} A ETE SCANNE PAR $myASTROPORT - IL CONTIENT ${VISITORCOINS} G1 -"
            fi

        fi

    ## DOES CURRENT IS RICHER THAN 100 G1
    ## IF GCHANGE ACCOUNT FOUND => SEND PALPE JUNE.
    # SEND MESSAGE TO GCHANGE MESSAGING. SEND 5 ★
    if [[ $CURCOINS -gt 100 && $PALPE != 0 ]]; then

            ## LE COMPTE VISITOR EST VIDE
            echo "## AUTOGRAPH $CURPLAYER SEND $PALPE TO ${QRCODE}"
            ## G1 PAYEMENT
            $MY_PATH/../tools/jaklis/jaklis.py \
            -k ${MYPLAYERKEY} pay \
            -a ${PALPE} -p ${QRCODE} -c "ASTRO:WELCOME:BRO" -m

            ## MESSAGE CESIUM +
            $MY_PATH/../tools/jaklis/jaklis.py \
            -n $myCESIUM -k ${MYPLAYERKEY} send \
            -d "${QRCODE}" -t "CADEAU" \
            -m "DE LA PART DE ${CURPLAYER} : ${PALPE} JUNE."

            ## SEND ONE ★ (NEXT STEP GCHANGE)
            [ $PALPE -ge 1 ] && my_star_level=1
            [ $PALPE -lt 50 ] && my_star_level=3
            [ $PALPE -ge 50 ] && my_star_level=5

            echo "★ SENDING $my_star_level STAR(s) ★"
            $MY_PATH/../tools/jaklis/jaklis.py -k ${MYPLAYERKEY} stars -p ${QRCODE} -n $my_star_level

    fi

     ls ~/.zen/tmp/${MOATS}/

            echo "************************************************************"
            echo "$VISITORCOINS (+ ${PALPE}) JUNE"
            echo "************************************************************"
    ##


fi

## USE PLAYER API OR MOVE TO G1PASS PGP QRCODE
###################################################################################################
# API TWO : ?qrcode=G1PUB&url=____&type=____

#~ if [[ ${AND} == "url" ]]; then
        #~ URL=${THIS}

        #~ if [[ ${URL} ]]; then

        #~ ## Astroport.ONE local use QRCODE Contains ${WHAT} G1PUB
        #~ g1pubpath=$(grep $QRCODE ~/.zen/game/players/*/.g1pub | cut -d ':' -f 1 2>/dev/null)
        #~ PLAYER=$(echo "$g1pubpath" | rev | cut -d '/' -f 2 | rev 2>/dev/null)

        #~ ## FORCE LOCAL USE ONLY. Remove to open 1234 API
        #~ [[ ! -d ~/.zen/game/players/${PLAYER} || ${PLAYER} == "" ]] \
        #~ && espeak "nope" \
        #~ && (echo "$HTTPCORS ERROR - QRCODE - NO ${PLAYER} ON BOARD !!"  | nc -l -p ${PORT} -q 1 > /dev/null 2>&1 &) \
        #~ && exit 1

        #~ ## Demande de copie d'une URL reçue.
             #~ [[ ${TYPE} ]] && CHOICE="${TYPE}" || CHOICE="Youtube"

            #~ ## CREATION TIDDLER "G1Voeu" G1CopierYoutube
            #~ # CHOICE = "Video" Page MP3 Web
            #~ ~/.zen/Astroport.ONE/ajouter_media.sh "${URL}" "${PLAYER}" "${CHOICE}" &

            #~ echo "$HTTPCORS <h1>OK</h1> - ${URL} AVAILABLE SOON<br>check you TW"   | nc -l -p ${PORT} -q 1 > /dev/null 2>&1 &
            #~ exit 0

        #~ else

            #~ (echo "$HTTPCORS ERROR - ${AND} - ${THIS} UNKNOWN"   | nc -l -p ${PORT} -q 1 > /dev/null 2>&1 &) && exit 1

        #~ fi
#~ fi


exit 0
