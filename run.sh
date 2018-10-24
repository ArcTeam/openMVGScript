#!/bin/bash
###############################################################
### IL FILE VA SALVATO NELLA CARTELLA PRINCIPALE DI OPENMGV ###
###############################################################

# imposto il log degli errori
# se un comando fallisce, lo script si interrompe e viene stampato l'errore relativo
set -e
core=$(nproc)
mog=false
mogMsg=""
# faccio partire il contatore per calcolare la durata totale dell'elaborazione
start=$(date +"%s")
startDate=$(date +%H:%M:%S)
# controllo che tutte le opzioni siano state dichiarate
usage() {
  echo ""
  echo "RELEASE 1.0"
  echo "USAGE: sh run.sh [options...]"
  echo "MANDATORY"
  echo "-i path assoluto della cartella che contiene le immagini"
  echo "-o path assoluto della cartella in cui salvare le elaborazioni"
  echo "-c <numero>(max 1095) numero di foto che compongono il cluster"
  echo ""
  echo "OPTIONAL"
  echo "-n <numero> numero dei core utilizzati dal software per l'elaborazione."
  echo "            Se non indicato verranno utilizzati tutti i cores disponibili."
  echo "            Se indichi un numero maggiore rispetto ai core disponibili, verranno comunque utilizzati solo i cores disponibili."
  echo "            Per sapere quanti sono i cores effettivi digita da terminale il comando nproc."
  echo "-m <widthxheight> utilizza mogrify per ridimensionare le foto prima di avviare l'elaborazione."
  echo "                  Puoi indicare anche solo la larghezza es. 4500x "
  echo "" 1>&2; exit 1;
}

while getopts ":i:o:c:n:m:" opt; do
  case $opt in
    i) input="$OPTARG" ;;
    o) output="$OPTARG" ;;
    c) cluster="$OPTARG" ;;
    n) core="$OPTARG" ;;
    m) res="$OPTARG"; mog=true ;;
    h) usage exit 1;;
    :) echo "l'opzione -$OPTARG prevede un valore!"; usage; exit 1;;
    *) echo "Attenzione, l'opzione -$OPTARG non è un'opzione valida"; usage; exit 1;;
  esac
done

shift "$(($OPTIND -1))"

if [ -z "$input" ] && [ -z "$output"] && [ -z "$cluster"]; then
    usage
fi

if [ -z "$input" ]
  then
    echo "devi indicare il percorso delle foto (-i)"
    # usage
    exit 1
fi

if [ -z "$output" ]
  then
    echo "devi indicare il la cartella in cui salvare le elaborazioni (-o)"
    # usage
    exit 1
fi

if [ -z "$cluster" ]
  then
    echo "devi indicare da quante foto deve essere composto il cluster (-c)"
    # usage
    exit 1
fi
if [ "$cluster" -gt 1095 ]
  then
    echo "Attenzione non puoi creare cluster con più di 1095 foto"
    # usage
    exit 1
fi

if [ -z "$core" ]
then
  echo "devi indicare il numero di core (-n)"
  # usage
  exit 1
fi
if [ "$res" ]
then
  mogMsg="Le foto sono state ridimensionate a $res px di larghezza"
  mogrify -verbose -resize $res $input/*.[Jj][Pp][Gg]
fi

# controllo se esiste la cartella output, altrimenti la creo
# se la cartella è già presente e se contiene i file di una precedente elaborazione, li cancello
if [ ! -d $output/output ]
then
  mkdir $output/output
  echo "la cartella output è stata creata"
else
  rm -r $output/output/ && mkdir $output/output
  echo "ok, la cartella output esiste già"
fi

# parto con il primo passaggio di openmvg
# se ci sono errori blocco lo script altrimenti vado al secondo passaggio
sequentialstart=$(date +"%s")
python ./software/SfM/SfM_SequentialPipeline.py $input $output/output/
sequentialend=$(date +"%s")
echo "primo passaggio terminato, parto con il secondo..."

# secondo passaggio
reconstructionstart=$(date +"%s")
Linux-x86_64-RELEASE/openMVG_main_openMVG2PMVS -i $output/output/reconstruction_sequential/robust.bin -o $output/output/reconstruction_sequential/sfmout
reconstructionend=$(date +"%s")
echo "secondo passaggio terminato, inizio l'elaborazione con cmvs..."

# cmvs
cmvsstart=$(date +"%s")
cmvs $output/output/reconstruction_sequential/sfmout/PMVS/ $cluster $core
cmvsend=$(date +"%s")

genOption $output/output/reconstruction_sequential/sfmout/PMVS/
echo "ok, fin qui tutto bene...modifico il file pmvs.sh"

sed -i 's/pmvs\//.\//g' $output/output/reconstruction_sequential/sfmout/PMVS/pmvs.sh
echo "file modificato, procedo con l'ultimo passaggio (pmvs)"

pmvsstart=$(date +"%s")
cd $output/output/reconstruction_sequential/sfmout/PMVS/
sh ./pmvs.sh
pmvsend=$(date +"%s")

end=$(date +"%s")
enddate=$(date +%H:%M:%S)
durata=$(($end-$start))
seqtime=$(($sequentialend-$sequentialstart))
rectime=$(($reconstructionend-$reconstructionstart))
cmvstime=$(($cmvsend-$cmvsstart))
pmvstime=$(($pmvsend-$pmvsstart))

echo "\n\n\n\n"
echo "Ottimo! Ce l'abbiamo fatta!!!!!!!"
echo "\n"
echo "Statistiche elaborazione"
echo "----------------------------------------------"
echo "numero di core utilizzati:  $core"
echo "numero di foto processate": $(ls -1 $input --file-type | grep -v '/$' | wc -l)
echo $mogMsg
echo "sequential pipeline:        $seqtime secondi"
echo "reconstruction:             $rectime secondi"
echo "cmvs:                       $cmvstime secondi"
echo "pmvs:                       $pmvstime secondi"
echo "elaborazione partita alle   $startDate"
echo "elaborazione terminata alle $enddate"
echo "----------------------------------------------"
echo "L'elaborazione è durata complessivamente $(($durata / 3600)) ore $(($durata / 60)) minuti e $(($durata % 60)) secondi"
xdg-open $output/output/reconstruction_sequential/sfmout/PMVS/models/
