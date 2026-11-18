# Footstep EQ for Warzone

*by **Lozy***

Senti meglio i **passi** dei nemici su Call of Duty: Warzone, con un clic.

Questo progetto installa un preset di equalizzazione per **[Equalizer APO](https://sourceforge.net/projects/equalizerapo/)** (gratuito e open source). Il preset abbassa i bassi che coprono tutto (esplosioni, veicoli, killstreak) e alza le frequenze dei passi, delle ricariche e dei cambi arma.

> ✅ **Non modifica nessun file del gioco.** Lavora sull'audio di Windows, come un normale equalizzatore. Nessun rischio per l'anti-cheat.
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
   - alla fine installa il preset e, se serve, ti propone il **riavvio**.

Se Equalizer APO era già installato e attivo sulle cuffie, il preset funziona subito, senza riavviare.

## Accendere e spegnere

Doppio clic su **`Attiva-Disattiva.bat`**. L'effetto è immediato, anche a gioco aperto, quindi è comodo per sentire la differenza.

## Disinstallare

Ci sono due possibilità:

| File | Cosa fa |
|---|---|
| **`Disinstalla-solo-preset.bat`** | Toglie solo il preset dei passi. Equalizer APO e gli altri preset restano come sono. |
| **`Rimuovi-EqualizerAPO.bat`** | Rimuove **completamente Equalizer APO** e riporta l'audio di Windows com'era prima. |

**`Rimuovi-EqualizerAPO.bat`** in dettaglio:
1. chiede conferma, perché smetteranno di funzionare *tutti* gli equalizzatori basati su Equalizer APO (anche Peace o altri preset);
2. salva una copia di sicurezza di tutti i preset in *Documenti → Footstep EQ - backup*;
3. avvia il **disinstallatore ufficiale** di Equalizer APO, che lo toglie da tutte le cuffie e i microfoni e cancella **solo i propri file** (mai l'intera cartella in cui era installato);
4. cancella anche la cartella dei preset e le voci rimaste nel registro: **rimozione pulita**;
5. controlla che sia tutto rimosso e propone il riavvio.

Sul PC resta solo la copia di sicurezza in Documenti: se non ti serve, cancellala.

Per reinstallare tutto in seguito basta di nuovo `Installa.bat`.

## Impostazioni consigliate nel gioco

| Impostazione | Valore |
|---|---|
| Volume musica | 0 |
| Volume effetti | Massimo |
| Audio Mix | Cuffie |
| Audio mono | Disattivato |

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
- **Il suono è troppo basso**: alza il volume di Windows. Il preset abbassa leggermente il volume generale per evitare distorsioni.

## Come funziona

- `scripts/install.ps1` trova Equalizer APO tramite il registro di Windows e individua le uscite audio su cui è attivo. Poi copia `presets/warzone_passi.txt`, limitandolo a quelle uscite (il microfono non viene toccato), e aggiunge una riga `Include:` al `config.txt`. Le altre righe del file restano come sono.
- Equalizer APO **non è incluso** nel progetto. L'installer scarica la versione 1.4.2 da SourceForge e la avvia **solo se l'impronta SHA-256 del file corrisponde** a quella scritta in `scripts/common.ps1`. In caso contrario non esegue niente e apre la pagina ufficiale.
- Test: `tests\run-tests.ps1` (test automatici, non modificano il sistema) e `tests\verify-system.ps1 -Expect Installed|Removed` (controlla lo stato reale del PC dopo un'installazione o una rimozione).
- `Installa.bat` con `-DemoGuide` (`powershell -File scripts\install.ps1 -DemoGuide`) mostra l'anteprima della guida senza modificare nulla.

Gli script sono in chiaro: puoi leggerli prima di eseguirli.

---

## English (short)

One-click installer for an **Equalizer APO** preset that makes footsteps clearer in Call of Duty: Warzone. It doesn't touch any game files. Download the ZIP, run `Installa.bat`, and follow the on-screen steps. Use `Attiva-Disattiva.bat` to toggle the preset `Disinstalla-solo-preset.bat` to remove only the preset, and `Rimuovi-EqualizerAPO.bat` to fully uninstall Equalizer APO (presets are backed up to Documents first). Not affiliated with Activision.

## Licenza

[MIT](LICENSE). Equalizer APO è un progetto separato, distribuito con la propria licenza (GPL-2.0).
