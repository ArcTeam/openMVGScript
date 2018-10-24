# openMVGScript
## script per automatizzare le ricostruzioni
### Il file va salvato nella cartella di installazione di openMVG

**UTILIZZO**

**sh run.sh -p [percorso assolute cartella immagini] -c [numero foto per cluster] [[-n numero core] [-m pixel larghezza]]**

Per avviare l'elaborazione' devi utilizzare le seguenti opzioni obbligatorie:

-i&nbsp;&nbsp;&nbsp;&nbsp; path assoluto della cartella che contiene le immagini

-o&nbsp;&nbsp;&nbsp;&nbsp; path assoluto della cartella in cui salvare le elaborazioni

-c&nbsp;&nbsp;&nbsp;&nbsp; <numero>(max 1095) numero di foto che compongono il cluster

Le prossime opzioni non sono obbligatorie e puoi non utilizzarle

Attenzione: se decidi di utilizzarle devi inserire un valore valido

-n&nbsp;&nbsp;&nbsp;&nbsp;<numero> numero dei core utilizzati dal software per l'elaborazione. Se non indicato verranno utilizzati tutti i cores disponibili.
Se indichi un numero maggiore rispetto ai core disponibili, verranno comunque utilizzati solo  i cores disponibili. Per sapere quanti sono i cores effettivi digita da terminale il comando
```
nproc
```

-m <widthxheight> utilizza mogrify per ridimensionare le foto prima di avviare l'elaborazione.

Puoi indicare anche solo la larghezza es. 4500x "
