################################################################################
# Author: Fred (support@qo-op.com)
# Version: 0.1
# License: AGPL-3.0 (https://choosealicense.com/licenses/agpl-3.0/)
################################################################################
################################################################################
## API: UPLANET
## Dedicated to OSM2IPFS & UPlanet Client App
# ?uplanet=EMAIL&salt=LAT&pepper=LON
## https://git.p2p.legal/qo-op/OSM2IPFS
################################################################################
MY_PATH="`dirname \"$0\"`"              # relative
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"  # absolutized and normalized
. "${MY_PATH}/../tools/my.sh"

start=`date +%s`

echo "PORT=$1
THAT=$2
AND=$3
THIS=$4
APPNAME=$5
WHAT=$6
OBJ=$7
VAL=$8
MOATS=$9
COOKIE=$10"
PORT="$1" THAT="$2" AND="$3" THIS="$4"  APPNAME="$5" WHAT="$6" OBJ="$7" VAL="$8" MOATS="$9" COOKIE="$10"
### transfer variables according to script
QRCODE=$(echo "$THAT" | cut -d ':' -f 1) # G1nkgo compatible

HTTPCORS="HTTP/1.1 200 OK
Access-Control-Allow-Origin: ${myASTROPORT}
Access-Control-Allow-Credentials: true
Access-Control-Allow-Methods: GET
Server: Astroport.ONE
Content-Type: text/html; charset=UTF-8

"
function urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

## CHECK FOR NOT PUBLISHING ALREADY (AVOID IPNS CRUSH)
alreadypublishing=$(ps axf --sort=+utime | grep -w 'ipfs name publish --key=' | grep -v -E 'color=auto|grep' | tail -n 1 | cut -d " " -f 1)
if [[ ${alreadypublishing} ]]; then
     echo "$HTTPCORS ERROR - (╥☁╥ ) - IPFS ALREADY PUBLISHING RETRY LATER"  | nc -l -p ${PORT} -q 1 > /dev/null 2>&1 &
     exit 1
fi

## START MANAGING UPLANET LAT/LON & PLAYER
mkdir -p ~/.zen/tmp/${MOATS}/

## GET PARAM, with case uplanet="" decalage !
PLAYER=${THAT}
[[ ${PLAYER} == "salt"  ]] && PLAYER="@"

[[ ${AND} == "salt" ]] && SALT=${THIS} || SALT=${AND}

[[ ${SALT} == "0" ]] && SALT="0.00"
input_number=${SALT}
if [[ ! $input_number =~ ^-?[0-9]{1,3}(\.[0-9]{1,2})?$ ]]; then
    (echo "$HTTPCORS ERROR - BAD LAT $LAT" | nc -l -p ${PORT} -q 1 > /dev/null 2>&1 &) &&  echo "(☓‿‿☓) Execution time was "`expr $(date +%s) - $start` seconds. &&  exit 0
else
    # If input_number has one decimal digit, add a trailing zero
    if [[ ${input_number} =~ ^-?[0-9]+\.[0-9]$ ]]; then
        input_number="${input_number}0"
    elif [[ ${input_number} =~ ^-?[0-9]+$ ]]; then
        # If input_number is an integer, add ".00"
        input_number="${input_number}.00"
    fi

    # Convert input_number to LAT with two decimal digits
    LAT="${input_number}"
fi

[[ ${APPNAME} == "pepper" ]] && PEPPER=${WHAT} || PEPPER=${APPNAME}

[[ ${PEPPER} == "0" ]] && PEPPER="0.00"
input_number=${PEPPER}
if [[ ! $input_number =~ ^-?[0-9]{1,3}(\.[0-9]{1,2})?$ ]]; then
    (echo "$HTTPCORS ERROR - BAD LON $LON" | nc -l -p ${PORT} -q 1 > /dev/null 2>&1 &) &&  echo "(☓‿‿☓) Execution time was "`expr $(date +%s) - $start` seconds. &&  exit 0
else
    # If input_number has one decimal digit, add a trailing zero
    if [[ ${input_number} =~ ^-?[0-9]+\.[0-9]$ ]]; then
        input_number="${input_number}0"
    elif [[ ${input_number} =~ ^-?[0-9]+$ ]]; then
        # If input_number is an integer, add ".00"
        input_number="${input_number}.00"
    fi

    # Convert input_number to LAT with two decimal digits
    LON="${input_number}"
fi

PASS=$(echo "${RANDOM}${RANDOM}${RANDOM}${RANDOM}" | tail -c-7)
## RECEIVED PASS
VAL="$(echo ${VAL} | detox --inline)" ## DETOX VAL
[[ ${OBJ} == "g1pub" && ${VAL} != "" ]] && PASS=${VAL}
### CHECK PLAYER EMAIL
EMAIL="${PLAYER,,}" # lowercase

[[ ! ${EMAIL} ]] && (echo "$HTTPCORS ERROR - MISSING ${EMAIL} FOR UPLANET LANDING" | nc -l -p ${PORT} -q 1 > /dev/null 2>&1 &) &&  echo "(☓‿‿☓) Execution time was "`expr $(date +%s) - $start` seconds. &&  exit 0

## CHECK WHAT IS EMAIL
if [[ "${EMAIL}" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$ ]]; then
    echo "VALID ${EMAIL} EMAIL OK"
else
    echo "BAD EMAIL"
    (echo "$HTTPCORS PLEASE PROVIDE A VALID EMAIL ${EMAIL} '"   | nc -l -p ${PORT} -q 1 > /dev/null 2>&1 &) && exit 0
fi

### CREATE G1VISA & G1Card
echo "${MY_PATH}/../tools/VISA.print.sh" "${EMAIL}"  "'"$LAT"'" "'"$LON"'" "'"$PASS"'" "'"$PASS"'"
${MY_PATH}/../tools/VISA.print.sh "${EMAIL}"  "$LAT" "$LON" "$PASS" "${PASS}"##
[[ ${EMAIL} != "" && ${EMAIL} != $(cat ~/.zen/game/players/.current/.player 2>/dev/null) ]] && rm -Rf ~/.zen/game/players/${EMAIL}/

# UPLANET #############################################
## OCCUPY COMMON CRYPTO KEY CYBERSPACE
## SALT="$LAT" PEPPER="$LON"
######################################################
echo "UMAP = $LAT:$LON"
echo "# CALCULATING MAP G1PUB WALLET"
${MY_PATH}/../tools/keygen -t duniter -o ~/.zen/tmp/${MOATS}/${G1PUB}/_cesium.key  "$LAT" "$LON"
G1PUB=$(cat ~/.zen/tmp/${MOATS}/${G1PUB}/_cesium.key | grep 'pub:' | cut -d ' ' -f 2)
[[ ! ${G1PUB} ]] && (echo "$HTTPCORS ERROR - (╥☁╥ ) - KEYGEN  COMPUTATION DISFUNCTON"  | nc -l -p ${PORT} -q 1 > /dev/null 2>&1 &) && exit 1
echo "MAPG1PUB : ${G1PUB}"

echo "# CALCULATING UMAP IPNS ADDRESS"
mkdir -p ~/.zen/tmp/${MOATS}/${G1PUB}
mkdir -p ~/.zen/tmp/${MOATS}/${LAT}_${LON}

ipfs key rm ${G1PUB} > /dev/null 2>&1
rm ~/.zen/tmp/${MOATS}/_ipns.priv 2>/dev/null
${MY_PATH}/../tools/keygen -t ipfs -o ~/.zen/tmp/${MOATS}/_ipns.priv "$LAT" "$LON"
UMAPNS=$(ipfs key import ${G1PUB} -f pem-pkcs8-cleartext ~/.zen/tmp/${MOATS}/_ipns.priv )
[[ ! ${UMAPNS} ]] && (echo "$HTTPCORS ERROR - (╥☁╥ ) - UMAPNS  COMPUTATION DISFUNCTON"  | nc -l -p ${PORT} -q 1 > /dev/null 2>&1 &) && exit 1
echo "UMAPNS : https://ipfs.copylaradio.com/ipns/${UMAPNS}"

###################################################
## GET NETWORK CACHE
echo "ipfs --timeout 60s get -o ~/.zen/tmp/${MOATS}/ /ipns/${UMAPNS}/"
ipfs --timeout 60s get -o ~/.zen/tmp/${MOATS}/ /ipns/${UMAPNS}/

####################################### Umap.png
## CREATING Umap_${LAT}_${LON}.png
echo "# OSM2IPFS ~/.zen/tmp/${MOATS}/Umap_${LAT}_${LON}.png"
UMAPGEN="/ipfs/QmQdB6ChBs7N1StVo3ikytMRBW4zCHL4pxEFP9Tq8kfjAV/Umap.html?southWestLat=$LAT&southWestLon=$LON&deg=0.01"
echo ${UMAPGEN}
echo "<meta http-equiv=\"refresh\" content=\"0; url='${UMAPGEN}'\" />" > ~/.zen/tmp/${MOATS}/Umap.html

## TODO find a better crawling method (pb tiles are not fully loaded before screenshot)
echo "chromium --headless --disable-gpu --screenshot=/tmp/Umap_${LAT}_${LON}.jpg --window-size=1200x1200 \"https://ipfs.copylaradio.com${UMAPGEN}\""
chromium --headless --disable-gpu --screenshot=/tmp/Umap.jpg --window-size=1200x1200 "https://ipfs.copylaradio.com${UMAPGEN}"
chromium --headless --disable-gpu --screenshot=/tmp/Umap.png --window-size=1200x1200 "https://ipfs.copylaradio.com${UMAPGEN}"


echo "<img src=G1Card.${EMAIL}.jpg \>" > ~/.zen/tmp/${MOATS}/G1Card.html
echo "<img src=G1Visa.${EMAIL}.jpg \>" > ~/.zen/tmp/${MOATS}/G1Visa.html
## ADD TO FRIENDS
echo "${EMAIL}" >> ~/.zen/tmp/${MOATS}/UFriends.txt

## COPYING FILES FROM ABROAD
cp /tmp/Umap.jpg ~/.zen/tmp/${MOATS}/
cp /tmp/Umap.png ~/.zen/tmp/${MOATS}/
rm -f ~/.zen/tmp/${MOATS}/G1*.jpg ## DELETE VISA FROM PREVIOUS VISITOR
cp ~/.zen/tmp/${PASS}##/G1Visa.${PASS}.jpg ~/.zen/tmp/${MOATS}/G1Visa.${EMAIL}.jpg
cp -f ~/.zen/tmp/${PASS}##/${PASS}.jpg ~/.zen/tmp/${MOATS}/G1Card.${EMAIL}.jpg
ls ~/.zen/tmp/${MOATS}/

### CREATE A G1VISA FOR PLAYER (IF PASS WAS GIVEN AND NO TW EXISTS YET)
if [[ ! -f ~/.zen/tmp/${MOATS}/TW/${EMAIL}/index.html ]]; then
    ## Create a redirection to PLAYER (EMAIL/PASS) TW
        mkdir -p ~/.zen/tmp/${MOATS}/TW/${EMAIL}
        ## CREATE TW LINK
        TWADD=$(${MY_PATH}/../tools/keygen -t ipfs "$EMAIL" "$PASS")
        echo "<meta http-equiv=\"refresh\" content=\"0; url='/ipns/${TWADD}'\" />" > ~/.zen/tmp/${MOATS}/TW/${EMAIL}/index.html
        if [[ ${PASS} ==  ${VAL} ]]; then
            ## CREATE OR TRANSFER TW ON CURRENT ASTROPORT
            (
            ${MY_PATH}/../tools/VISA.new.sh "${EMAIL}" "${PASS}" "${EMAIL}" "UPlanet" "/ipns/${UMAPNS}" "${LAT}" "${LON}" >> ~/.zen/tmp/email.${EMAIL}.${MOATS}.txt
            ${MY_PATH}/../tools/mailjet.sh "${EMAIL}" ~/.zen/tmp/email.${EMAIL}.${MOATS}.txt ## Send VISA.new log to EMAIL
            ) &
        fi
fi

## MAKE A MESSAGE
echo "<html>
    <head>
    <title>[Astroport] $LAT $LON WELCOME ${EMAIL} </title>
        <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            background-color: #f0f0f0;
            padding: 20px;
        }
        h1 {
            color: #0077cc;
        }
        h2 {
            color: #333;
        }
        img {
            cursor: pointer;
        }
    </style>
    </head><body>
    <h1>Welcome UPlanet Keeper!</h1>
    <h1>Registration for $LAT/$LON</h1>
    <br>    <img width='300' height='300' src='Umap.jpg'  alt='UPlanet recorded Image' \>
    <br> <a href='Umap.html >OSM2IPFS</a>
    <br> UMap Key : <a target=localhost href=http://ipfs.localhost:8080/ipns/${UMAPNS}>LOCALHOST</a> / <a target=localhost href=https://ipfs.copylaradio.com/ipns/${UMAPNS}>WAN</a>
    <br> <h2>${EMAIL}</h2>
    UPlanet ID's
        <br>
    <button id='printButton'>Print</button>
<h1>Umap Visa</h1>
<br>    <img src=G1Visa.${EMAIL}.jpg alt='G1Visa' \>
<h1>Umap Card</h1>
<br>    <img src=G1Card.${EMAIL}.jpg alt='G1Card' \>
<br>
    <script>
        // Function to print the page
        function printPage() {
            window.print();
        }
        // Add click event listener to the print button
        document.getElementById('printButton').addEventListener('click', printPage);
    </script>

    <h2>See <a href='./TW'>TW's</a> here</h2>

<br> Now enhance UPLANET.sh !
        <br><br>ASTROPORT REGISTERED Crypto Commons : $LAT $LON : ${MOATS} : $(date)
     </body></html>" > ~/.zen/tmp/${MOATS}/MESSAGE.html

 # $(find ~/.zen/tmp/${MOATS}/ -type d -regex '.*[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}.*')

## TAKING CARE OF THE CHAIN
########################################
IPFSROOT=$(ipfs add -rwHq  ~/.zen/tmp/${MOATS}/* | tail -n 1)
########################################
ZCHAIN=$(cat ~/.zen/tmp/${MOATS}/${G1PUB}/_chain 2>/dev/null)
ZMOATS=$(cat ~/.zen/tmp/${MOATS}/${G1PUB}/_moats 2>/dev/null)
[[ ${ZCHAIN} && ${ZMOATS} ]] \
    && cp ~/.zen/tmp/${MOATS}/${G1PUB}/_chain ~/.zen/tmp/${MOATS}/${G1PUB}/_chain.${ZMOATS} \
    && echo "UPDATING MOATS"

## UPDATE HPASS last G1Visa PASS
HPASS=$(echo $PASS | sha512sum | cut -d ' ' -f 1)
echo "${HPASS}" > ~/.zen/tmp/${MOATS}/${G1PUB}/_${EMAIL}.HPASS

## DOES CHAIN CHANGED or INIT ?
[[ ${ZCHAIN} != ${IPFSROOT} || ${ZCHAIN} == "" ]] \
    && echo "${IPFSROOT}" > ~/.zen/tmp/${MOATS}/${G1PUB}/_chain \
    && echo "${MOATS}" > ~/.zen/tmp/${MOATS}/${G1PUB}/_moats \
    && IPFSROOT=$(ipfs add -rwHq  ~/.zen/tmp/${MOATS}/* | tail -n 1) && echo "ROOT was ${ZCHAIN}"

################################################################################
## WRITE INTO 12345 SWARM CACHE LAYER
mkdir -p ~/.zen/tmp/${IPFSNODEID}/UPLANET/_${LAT}_${LON}/_visitors
echo "<meta http-equiv=\"refresh\" content=\"0; url='/ipns/${UMAPNS}'\" />" > ~/.zen/tmp/${IPFSNODEID}/UPLANET/_${LAT}_${LON}/index.html
echo "${EMAIL}:${IPFSROOT}:${MOATS}" >> ~/.zen/tmp/${IPFSNODEID}/UPLANET/_${LAT}_${LON}/_visitors/${EMAIL}.log
########################################
########################################
echo "Now IPFSROOT is http://ipfs.localhost:8080/ipfs/${IPFSROOT}"

    (
    ipfs name publish --key=${G1PUB} /ipfs/${IPFSROOT}
    end=`date +%s`
    echo "(IPNS) publish time was "`expr $end - $start` seconds.
    ) &


## HTTP nc ON PORT RESPONSE
echo "$HTTPCORS
    <html>
    <head>
    <title>[Astroport] $LAT $LON WELCOME ${EMAIL} </title>
    <meta http-equiv=\"refresh\" content=\"10; url='https://ipfs.copylaradio.com/ipfs/${IPFSROOT}/message.html'\" />
    </head><body>
    <h1>$LAT/$LON UPlanet common blockchain</h1>
    <br>UMAP : <a target=localhost href=http://ipfs.localhost:8080/ipns/${UMAPNS}>http://ipfs.localhost:8080/ipns/${UMAPNS}</a>
    <br>CHAIN : <a target=wan href=https://ipfs.copylaradio.com/ipfs/${IPFSROOT}>https://ipfs.copylaradio.com/ipfs/${IPFSROOT}</a>
    <br> <h2>${EMAIL} <bold>your PASS is $PASS</bold></h2>
    ---
    <br>
( ⚆_⚆) if you entered PASS<br>
    $(cat ~/.zen/tmp/email.${EMAIL}.${MOATS}.txt 2>/dev/null)
<br>(☉_☉ ) your TW has move to ASTROPORT<br>
        <br><br>${EMAIL} REGISTERED : ${MOATS} : $(date)
     </body></html>" > ~/.zen/tmp/${MOATS}/http.rep
cat ~/.zen/tmp/${MOATS}/http.rep | nc -l -p ${PORT} -q 1 > /dev/null 2>&1 &

end=`date +%s`
echo "(TW) MOA Operation time was "`expr $end - $start` seconds.
exit 0
