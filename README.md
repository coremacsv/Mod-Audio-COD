# Mod Audio COD

*by **Lozy***

Senti meglio i **passi** dei nemici su Call of Duty: Warzone, con un clic.

Questo progetto installa un preset di equalizzazione per **[Equalizer APO](https://sourceforge.net/projects/equalizerapo/)** (gratuito e open source). Il preset abbassa i bassi che coprono tutto (esplosioni, veicoli, killstreak) e alza le frequenze dei passi, delle ricariche e dei cambi arma.

> ✅ **Non modifica nessun file del gioco.** Lavora sull'audio di Windows, come un normale equalizzatore, e cambia solo le **impostazioni audio** di Warzone (le stesse del menu Audio). Nessun rischio per l'anti-cheat.
>
> ⚠️ Progetto non ufficiale e **non affiliato con Activision**. "Call of Duty" e "Warzone" sono marchi dei rispettivi proprietari.

---

## Requisiti

- PC con **Windows 10 o 11** (non funziona su console)
- Cuffie collegate al PC

## Installazione

1. Scarica questo progetto: **Code → Download ZIP**.
   *Consigliato:* prima di estrarlo, tasto destro sullo ZIP → **Proprietà** → spunta **Sblocca** → **OK**. Così Windows non mostrerà avvisi.
2. Estrai lo ZIP e fai doppio clic su **`Installa.bat`**.
   - Windows può mostrare un avviso, normale per i programmi scaricati da Internet senza firma digitale a pagamento:
     - finestra **"Apri file - Avviso di sicurezza"** (*Impossibile verificare l'autore*) → clicca **Esegui**;
     - schermata blu **"PC protetto da Windows"** → **Ulteriori informazioni → Esegui comunque**.
   - Premi **Sì** quando Windows chiede i permessi di amministratore.
3. In basso a destra compare una **finestra-guida** che ti dice cosa cliccare a ogni passaggio e si aggiorna da sola:
   - se **Equalizer APO non è installato**, lo scarica dalla pagina ufficiale, controlla che il file sia quello originale e ne avvia l'installazione;
   - quando si apre il **Device Selector**, ti dice di spuntare **solo l'uscita delle tue cuffie**;
   - installa il preset e **imposta da solo l'audio di Warzone** (vedi sotto), poi mostra una schermata con l'esito di ogni voce;
   - alla fine, se serve, ti propone il **riavvio**.

**Tieni Warzone chiuso durante l'installazione**: se è aperto, il programma ti chiede di chiuderlo, altrimenti il gioco sovrascriverebbe le impostazioni alla chiusura.

Se Equalizer APO era già installato e attivo sulle cuffie, il preset funziona subito, senza riavviare.

## Disinstallare

Doppio clic su **`Rimuovi-EqualizerAPO.bat`**: rimuove **completamente Equalizer APO** e riporta l'audio di Windows com'era prima.

In dettaglio:
1. chiede conferma, perché smetteranno di funzionare *tutti* gli equalizzatori basati su Equalizer APO (anche Peace o altri preset);
2. avvia il **disinstallatore ufficiale** di Equalizer APO, che lo toglie da tutte le cuffie e i microfoni e cancella **solo i propri file** (mai l'intera cartella in cui era installato);
3. cancella anche la cartella dei preset e le voci rimaste nel registro: **rimozione pulita, sul PC non resta niente**;
4. controlla che sia tutto rimosso e propone il riavvio.

Per reinstallare tutto in seguito basta di nuovo `Installa.bat`.

## Impostazioni audio di Warzone (importante)

Il preset è pensato per queste impostazioni del gioco. Con valori diversi, soprattutto con la **Compensazione udito asimmetrico** attiva, l'audio può sembrare **tappato**.

`Installa.bat` le **imposta e verifica da solo** nei file delle impostazioni del gioco, cioè le stesse del menu Audio. Poi mostra una schermata riepilogativa: ✓ impostata, ✗ da cambiare a mano, ⚠ da controllare a mano.

| Launcher | Impostazioni del gioco |
|---|---|
| Battle.net | automatiche (`%LOCALAPPDATA%\Activision\Call of Duty\players`) |
| Steam / altre versioni | automatiche se i file sono in `Documenti\Call of Duty\players`, anche su OneDrive |
| App Xbox / Game Pass | di solito i file non sono leggibili: la schermata finale elenca le voci da mettere **a mano** |

Il preset per i passi funziona con **tutti** i launcher: cambia solo se le impostazioni del gioco vengono messe in automatico o a mano. Se il gioco usa un formato dei file che il programma non conosce, il programma non li tocca.

| Sezione | Impostazione | Valore | |
|---|---|---|---|
| Volumi | Volume di gioco generale | 80 | automatico |
| Volumi | Volume musica in gioco | 0 | automatico |
| Volumi | Volume dialoghi | 50 | automatico |
| Volumi | Volume effetti | 100 | automatico |
| Volumi | Volume musica filmati | 0 | automatico |
| Dispositivo audio | Dispositivo suoni del gioco | Dispositivo sistema predefinito | automatico |
| Dispositivo audio | Uscita altoparlanti | Stereo | automatico |
| Dispositivo audio | Modalità cuffie migliorata | No | automatico |
| Globale | Mix audio | Cuffie | automatico |
| Globale | Audio mono | No | automatico |
| Globale | Disattiva audio quando ridotto a icona | No | automatico |
| Globale | Disattiva musica su licenza | No | automatico |
| Globale | **Compensazione udito asimmetrico** | **No** | ⚠ **controllala sempre** nel gioco (se è attiva la schermata la segnala in rosso) |
| Funzionalità | Riduci audio acufene | No | automatico |
| Funzionalità | Avvisi per colpi alla testa e uccisioni | Sì | ⚠ a mano |

La **Compensazione udito asimmetrico** non è nei file di testo ma in un file binario del profilo: il programma la **legge** (senza mai modificare quel file): se è attiva la segnala in **rosso**. In ogni caso ti chiede **sempre** di controllarla nel gioco, perché un aggiornamento di Warzone potrebbe cambiare il modo in cui viene salvata.

Nel gioco i quattro volumi (musica in gioco, dialoghi, effetti, musica filmati) si vedono solo dopo aver cliccato **Mostra di più** sotto *Volume di gioco generale*.

Gli "Avvisi per colpi alla testa e uccisioni" non influiscono sul preset: controllali a mano se vuoi la configurazione identica. Una volta ogni tanto conviene dare un'occhiata alle impostazioni, perché Warzone può riprendere i valori salvati online.

Se usi l'audio 3D o spaziale del gioco, **disattiva Windows Sonic e Dolby Atmos** in Windows. Due elaborazioni spaziali insieme rendono il suono confuso.

## Regolare il suono

Il preset installato si trova nella cartella `config` di Equalizer APO, con il nome `warzone_passi.txt`. Modifica i valori `Gain` e salva: il cambiamento è immediato.

| Problema | Cosa cambiare |
|---|---|
| Passi ancora deboli | 2500 e 4000 Hz a +5 o +6 dB |
| Suono troppo metallico | 2500 e 4000 Hz a +2 o +3 dB |
| Le esplosioni coprono ancora | 120 Hz a -6 dB |
| Suono troppo vuoto | 120 Hz a -2 dB |

## Problemi comuni

- **Non cambia niente**: Equalizer APO probabilmente è attivo sull'uscita sbagliata. Apri *Start → Equalizer APO → Device Selector*, spunta le cuffie, riavvia ed esegui di nuovo `Installa.bat`.
- **Hai cambiato cuffie**: esegui di nuovo `Installa.bat`, che aggiorna il preset sulle nuove uscite.
- **Cuffie con un loro software** (G HUB, iCUE, SteelSeries GG…): spegni l'equalizzatore di quel software, altrimenti si somma a questo.
- **Il gioco si chiude appena lo apri** (dopo l'installazione): riavvia il PC. Equalizer APO si attiva solo dopo il riavvio. Installa sempre con Call of Duty e il suo launcher chiusi: `Installa.bat` te lo chiede. Se si chiude ancora dopo il riavvio, togli tutto con `Rimuovi-EqualizerAPO.bat` e apri una segnalazione su GitHub.
- **Il suono è troppo basso**: alza il volume di Windows. Il preset abbassa leggermente il volume generale per evitare distorsioni.

## Come funziona

- `scripts/install.ps1` trova Equalizer APO tramite il registro di Windows e individua le uscite audio su cui è attivo. Poi copia `presets/warzone_passi.txt`, limitandolo a quelle uscite (il microfono non viene toccato), e aggiunge una riga `Include:` al `config.txt`. Le altre righe del file restano come sono.
- Equalizer APO **non è incluso** nel progetto. L'installer scarica la versione 1.4.2 da SourceForge e la avvia **solo se l'impronta SHA-256 del file corrisponde** a quella scritta in `scripts/common.ps1`. In caso contrario non esegue niente e apre la pagina ufficiale.
- Test: `tests\run-tests.ps1` (test automatici, non modificano il sistema) e `tests\verify-system.ps1 -Expect Installed|Removed` (controlla lo stato reale del PC dopo un'installazione o una rimozione).
- `Installa.bat` con `-DemoGuide` (`powershell -File scripts\install.ps1 -DemoGuide`) mostra l'anteprima della guida senza modificare nulla.

Gli script sono in chiaro: puoi leggerli prima di eseguirli.

---

## English (short)

One-click installer for an **Equalizer APO** preset that makes footsteps clearer in Call of Duty: Warzone. It doesn't touch any game files. Download the ZIP, run `Installa.bat`, and follow the on-screen steps. Run `Rimuovi-EqualizerAPO.bat` to fully uninstall Equalizer APO and restore Windows audio, leaving nothing behind. Not affiliated with Activision.

## Licenza

[MIT](LICENSE). Equalizer APO è un progetto separato, distribuito con la propria licenza (GPL-2.0).
