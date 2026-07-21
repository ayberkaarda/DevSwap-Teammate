import consumer from "channels/consumer"

const currentUserName = document.querySelector('meta[name="current-user"]')?.content || "Ayberk";

function getOmniStats() {
    return JSON.parse(document.querySelector('meta[name="omni-stats"]')?.content || '{}');
}

function getCurrentRoomSlug() {
    return document.getElementById('chat-messages')?.dataset.roomSlug || "genel";
}

// Basit Markdown (Syntax) Dönüştürücü
function parseMessage(text) {


    return text.replace(/```([\s\S]*?)```/g, '<pre class="bg-[var(--terminal-bg)] border border-terminal-border p-3 my-2 text-terminal-accent-2 overflow-x-auto rounded shadow-inner text-xs"><code>$1</code></pre>');

}

let typingTimer;


function subscribeToRoom(roomSlug) {
    return consumer.subscriptions.create({ channel: "TerminalChatChannel", user: currentUserName, room: roomSlug }, {

    connected() {
        this.perform('appear', { user: currentUserName });
    },

    received(data) {
        if (data.type === "presence") {
            document.querySelectorAll(`.presence-badge[data-user="${data.user}"]`).forEach(badge => {
                if (data.status === "çevrimiçi") {
                    badge.className = "presence-badge text-[10px] px-2 py-0.5 rounded-full border transition-all border-emerald-500 text-prompt-color bg-emerald-950/30";
                    badge.innerText = "Çevrimiçi";
                } else {
                    badge.className = "presence-badge text-[10px] px-2 py-0.5 rounded-full border transition-all border-gray-600 text-terminal-text-muted bg-gray-900";
                    badge.innerText = "Çevrimdışı";
                }
            });

            const logContainer = document.getElementById('network-logs');
            if (logContainer) {
                const time = new Date().toLocaleTimeString('tr-TR', { hour12: false });
                const isOnline = data.status === "çevrimiçi";
                const action = isOnline ? "bağlantı kurdu (Handshake_OK)" : "ağdan koptu (Conn_Lost)";
                const color = isOnline ? "text-prompt-color" : "text-rose-500";

                const logHTML = `
          <div class="mb-1 animate-fade-in-down">
            <span class="text-terminal-text-muted">[${time}]</span>
            <span class="${color} font-bold">AUTH_SYS:</span> Node_<span class="text-terminal-text">${data.user}</span> ${action}.
          </div>
        `;
                logContainer.insertAdjacentHTML('afterbegin', logHTML);
            }
            return;
        }

        if (data.type === "read_receipt") {
            const statusSpan = document.getElementById(`msg-status-${data.message_id}`);
            if (statusSpan) {
                statusSpan.innerText = "[Görüldü]";
                statusSpan.classList.replace('text-gray-500', 'text-terminal-accent-2');
            }
            return;
        }

        if (data.type === "typing" && data.user !== currentUserName) {
            const indicator = document.getElementById('typing-indicator');
            if (indicator) {
                indicator.innerHTML = `[SYS: Node_<span class="text-prompt-color animate-pulse">${data.user}</span> is_typing...]`;
                indicator.classList.remove('opacity-0');

                clearTimeout(typingTimer);
                typingTimer = setTimeout(() => {
                    indicator.classList.add('opacity-0');
                }, 2000);
            }
            return;
        }

        // Emoji tepkisi yayini: guncel emoji sayilarina gore #msg-reactions-<id>
        // konteynerini yeniden kur. Cip yapisi _chat_message.html.erb (server-render)
        // ile BIREBIR ayni olmali (class="reaction-chip ..." + data-action/data-emoji).
        if (data.type === "message_reaction") {
            const container = document.getElementById(`msg-reactions-${data.message_id}`);
            if (container) {
                const entries = Object.entries(data.reactions || {});
                container.innerHTML = entries.map(([emoji, count]) => `
          <button type="button" data-action="chat-message#react" data-emoji="${emoji}"
                  class="reaction-chip inline-flex items-center gap-0.5 text-[11px] leading-none px-1.5 py-0.5 rounded-full border border-prompt-color/30 bg-prompt-color/10 text-prompt-color hover:bg-prompt-color/20 transition-colors">
            ${emoji} <span>${count}</span>
          </button>`).join('');
                container.classList.toggle('mt-1', entries.length > 0);
            }
            return;
        }

        // Mesaj duzenlendi: govdeyi guncelle ve "(düzenlendi)" isaretini gorunur yap.
        if (data.type === "message_edited") {
            const msgNode = document.getElementById(`msg-${data.id}`);
            if (msgNode) {
                const bodyNode = msgNode.querySelector('[data-chat-message-target="body"]');
                if (bodyNode) bodyNode.textContent = data.message;
                const marker = msgNode.querySelector('[data-chat-message-target="editedMarker"]');
                if (marker) marker.classList.remove('hidden');
            }
            return;
        }

        // Mesaj silindi: DOM'dan kaldir.
        if (data.type === "message_deleted") {
            const msgNode = document.getElementById(`msg-${data.id}`);
            if (msgNode) msgNode.remove();
            return;
        }

        if (data.type === "message") {
            const indicator = document.getElementById('typing-indicator');
            if (indicator) indicator.classList.add('opacity-0');

            const messagesContainer = document.getElementById('chat-messages');
            const isMine = (data.user === currentUserName);
            const statusLabel = isMine ? `<span id="msg-status-${data.id}" class="text-[10px] text-terminal-text-muted ml-2 tracking-widest">[İletildi]</span>` : '';

            let formattedMessage = parseMessage(data.message);

            // YENİLİK 1: Mention (Etiketleme) Sistemi
            const isMentioned = !isMine && data.message.includes(`@${currentUserName}`);
            const mentionClass = isMentioned ? "bg-prompt-color/20 border-l-2 border-prompt-color pl-2 py-1" : "";
            if (isMentioned) {
                formattedMessage = formattedMessage.replace(`@${currentUserName}`, `<span class="bg-prompt-color text-[var(--terminal-bg)] px-1 font-bold">@${currentUserName}</span>`);
            }

            const messageHTML = `
        <div class="mb-3 font-mono text-sm leading-relaxed ${mentionClass} opacity-0 translate-y-2 transition-all duration-300 ease-out" id="msg-${data.id}">
          <span class="text-prompt-color font-bold">${data.user}</span>
          <span class="text-terminal-text-muted">~%</span>
          <span class="text-terminal-text ml-2 block sm:inline mt-1 sm:mt-0">${formattedMessage}</span>
          ${statusLabel}
        </div>
      `;
            messagesContainer.insertAdjacentHTML('beforeend', messageHTML);
            messagesContainer.scrollTop = messagesContainer.scrollHeight;

            // EKLEME 1: Yeni mesaj için fade-in + slide-up animasyonu
            const newMessageNode = document.getElementById(`msg-${data.id}`);
            if (newMessageNode) {
                requestAnimationFrame(() => {
                    newMessageNode.classList.remove('opacity-0', 'translate-y-2');
                    newMessageNode.classList.add('opacity-100', 'translate-y-0');
                });
            }

            // EKLEME 2: Varsa #dev-feed-terminal widget'ına kısa bir log satırı yaz
            const devFeedWidget = document.getElementById('dev-feed-terminal');
            const devFeedLog = document.getElementById('dev-feed-log');
            if (devFeedWidget && devFeedLog) {
                const feedTime = new Date().toLocaleTimeString('tr-TR', { hour12: false });


                const feedLineHTML = `<div class="opacity-0 transition-opacity duration-500"><span class="text-terminal-text-muted">[${feedTime}]</span> <span class="text-prompt-color font-bold">SIGNAL:</span> Yeni sinyal: <span class="text-terminal-text">${data.user}</span></div>`;

                devFeedLog.insertAdjacentHTML('afterbegin', feedLineHTML);

                const newFeedLine = devFeedLog.firstElementChild;
                if (newFeedLine) {
                    requestAnimationFrame(() => {
                        newFeedLine.classList.remove('opacity-0');
                        newFeedLine.classList.add('opacity-100');
                    });
                }

                while (devFeedLog.childElementCount > 5) {
                    devFeedLog.removeChild(devFeedLog.lastElementChild);
                }
            }

            if (!isMine) {
                this.perform('mark_read', { message_id: data.id });
            }
        }
    }
    });
}

let subscription = subscribeToRoom(getCurrentRoomSlug());

window.addEventListener('beforeunload', () => {
    subscription.perform('disappear', { user: currentUserName });
});

// Sekmeye tıklayınca (Turbo frame yenilenince) eski odadan çık, yeni odaya abone ol
document.addEventListener('turbo:frame-load', (event) => {
    if (event.target.id === 'chat_panel') {
        subscription.unsubscribe();
        subscription = subscribeToRoom(getCurrentRoomSlug());
    }
});

// YENİLİK 2: Kesin Form Temizleme ve Slash Commands Motoru (GÜNCELLENDİ)
const COMMAND_HISTORY_KEY = "devswap_chat_command_history";

// CSRF token'ı meta etiketinden okur (dashboard_grid_controller.js ile AYNI desen).
function csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.content : "";
}

// [SYS_EXEC] sistem yanit satirini, kozmetik komutlarla BIREBIR ayni gorsel
// muameleyle chat'e ekler. Async komutlar (/mute, /unmute) sunucu yanitini
// bekledikten sonra bu fonksiyonla sonucu (basari/hata) gosterir.
function renderSysResponse(messagesContainer, sysResponse) {
    if (!sysResponse || !messagesContainer) return;
    const cmdHTML = `
            <div class="mb-3 mt-2 border-l-2 border-terminal-accent-2 pl-2 bg-terminal-accent-2/20 py-2 font-mono text-sm">
              <span class="text-terminal-accent-2 font-bold text-xs tracking-widest">[SYS_EXEC]</span>
              <span class="text-terminal-text ml-2">${sysResponse}</span>
            </div>
          `;
    messagesContainer.insertAdjacentHTML('beforeend', cmdHTML);
    messagesContainer.scrollTop = messagesContainer.scrollHeight;
}

// Sunucu-etkili slash komutu (/mute, /unmute) icin kimlik dogrulamali POST.
// Donen JSON'daki `message` alanini sistem yaniti olarak gosterir (basari VEYA hata).
async function postChatCommand(url, payload, messagesContainer) {
    try {
        const response = await fetch(url, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                Accept: "application/json",
                "X-CSRF-Token": csrfToken()
            },
            body: JSON.stringify(payload)
        });
        const data = await response.json().catch(() => ({}));
        renderSysResponse(messagesContainer, data.message || "Komut çalıştırılamadı.");
    } catch (error) {
        renderSysResponse(messagesContainer, "Sunucuya ulaşılamadı, komut çalıştırılamadı.");
    }
}

let commandHistory = JSON.parse(sessionStorage.getItem(COMMAND_HISTORY_KEY) || "[]");
let historyIndex = commandHistory.length;

// EVENT DELEGATION: Handler'lar document'a baglanir. Oda sekmesi (Turbo Frame)
// degisince #terminal-form/input DOM'dan silinip yeniden olusturulsa da,
// document uzerindeki delegasyon her zaman guncel DOM node'una calisir -
// yeniden baglama gerekmez.
document.addEventListener('keydown', (e) => {
    const input = e.target;
    if (!input.matches('#terminal-form input[type="text"]')) return;

    // 1. SLASH KOMUTLARI: Sunucuya gitmeden klavye seviyesinde (Enter) yakala ve çalıştır
    if (e.key === 'Enter' && input.value.trim().startsWith('/')) {
        e.preventDefault(); // Formun sunucuya gitmesini KESİN olarak durdur
        const messagesContainer = document.getElementById('chat-messages');
        const text = input.value.trim();


        commandHistory.push(text);
        historyIndex = commandHistory.length;
        sessionStorage.setItem(COMMAND_HISTORY_KEY, JSON.stringify(commandHistory));

        let sysResponse = '';
        if (text === '/clear') {
            if (messagesContainer) messagesContainer.innerHTML = '';
            sysResponse = 'Terminal ekranı temizlendi.';
        } else if (text === '/whoami') {
            sysResponse = `Yetki seviyesi: [ROOT] -> Node_${currentUserName}`;
        } else if (text === '/ping') {
            const latency = Math.floor(Math.random() * 12) + 4;
            sysResponse = `PONG! Ağ gecikmesi: ${latency}ms`;
        } else if (text === '/omni') {
            const omniStats = getOmniStats();
            sysResponse = `Node: ${currentUserName} | GitHub: ${omniStats.github_connected ? "bagli" : "bagli degil"}<br>Teaching: ${omniStats.teaching ?? 0} skill | Learning: ${omniStats.learning ?? 0} skill<br>Vektor: teach=${omniStats.vector_teach ? "var" : "yok"}, learn=${omniStats.vector_learn ? "var" : "yok"}`;
        } else if (text.startsWith('/mute ') || text === '/mute') {
            // GERCEK komut: sunucuya POST, Mute kaydi olusturur (staff-only, server-enforced).
            // Sozdizimi: /mute <isim> <sure>  ornek: /mute Ayberk 30 dakika
            const rest = text.slice('/mute'.length).trim();
            const firstSpace = rest.indexOf(' ');
            const username = firstSpace === -1 ? rest : rest.slice(0, firstSpace);
            const duration = firstSpace === -1 ? '' : rest.slice(firstSpace + 1).trim();
            if (!username) {
                sysResponse = 'Kullanım: /mute &lt;isim&gt; &lt;süre&gt; (örn. /mute Ayberk 30 dakika)';
            } else {
                postChatCommand('/chat_commands/mute', { username, duration }, messagesContainer);
            }
        } else if (text.startsWith('/unmute ') || text === '/unmute') {
            // GERCEK komut: sunucuya POST, aktif susturmayi pasifize eder (staff-only, server-enforced).
            const username = text.slice('/unmute'.length).trim();
            if (!username) {
                sysResponse = 'Kullanım: /unmute &lt;isim&gt; (örn. /unmute Ayberk)';
            } else {
                postChatCommand('/chat_commands/unmute', { username }, messagesContainer);
            }
        } else if (text.startsWith('/block ') || text === '/block') {
            // GERCEK komut: sunucuya POST, Block kaydi olusturur. Self-service —
            // staff yetkisi GEREKMEZ, herkes kendini korumak icin engelleyebilir.
            const username = text.slice('/block'.length).trim();
            if (!username) {
                sysResponse = 'Kullanım: /block &lt;isim&gt; (örn. /block Ayberk)';
            } else {
                postChatCommand('/chat_commands/block', { username }, messagesContainer);
            }
        } else if (text.startsWith('/unblock ') || text === '/unblock') {
            // GERCEK komut: sunucuya POST, aktif engeli kaldirir.
            const username = text.slice('/unblock'.length).trim();
            if (!username) {
                sysResponse = 'Kullanım: /unblock &lt;isim&gt; (örn. /unblock Ayberk)';
            } else {
                postChatCommand('/chat_commands/unblock', { username }, messagesContainer);
            }
        } else if (text.startsWith('/ban ') || text === '/ban') {
            // GERCEK komut: sunucuya POST, BannedAccount kaydi olusturur/gunceller (admin-only, server-enforced).
            // Sozdizimi: /ban <isim> [sure gun]  ornek: /ban Ayberk 7 gun  (suresiz icin sureyi bos birak)
            const rest = text.slice('/ban'.length).trim();
            const firstSpace = rest.indexOf(' ');
            const username = firstSpace === -1 ? rest : rest.slice(0, firstSpace);
            const duration = firstSpace === -1 ? '' : rest.slice(firstSpace + 1).trim();
            if (!username) {
                sysResponse = 'Kullanım: /ban &lt;isim&gt; [süre gün] (örn. /ban Ayberk 7 gün)';
            } else {
                postChatCommand('/chat_commands/ban', { username, duration }, messagesContainer);
            }
        } else if (text.startsWith('/unban ') || text === '/unban') {
            // GERCEK komut: sunucuya POST, aktif bani pasifize eder (admin-only, server-enforced).
            const username = text.slice('/unban'.length).trim();
            if (!username) {
                sysResponse = 'Kullanım: /unban &lt;isim&gt; (örn. /unban Ayberk)';
            } else {
                postChatCommand('/chat_commands/unban', { username }, messagesContainer);
            }
        } else if (text.startsWith('/report ') || text === '/report') {
            // KOZMETIK/CLIENT-SIDE: sunucuya gitmez. Ismi ayristirip ayni global
            // "report:open" event'ini tetikler; katmandaki modal acilir, gonderimi
            // kendisi yapar (form). Ornek: /report Ayberk
            const username = text.slice('/report'.length).trim();
            if (!username) {
                sysResponse = 'Kullanım: /report &lt;isim&gt; (örn. /report Ayberk)';
            } else {
                document.dispatchEvent(new CustomEvent("report:open", { detail: { username } }));
                sysResponse = `Şikayet paneli açıldı: ${username}`;
            }
        } else if (text === '/rules') {
            // KOZMETIK: kurallarin kisa ozeti (tam metin /terms sayfasinda).
            sysResponse = 'DevSwap Kurallari (ozet):<br>' +
                '&nbsp;&nbsp;1. Taciz, hakaret, nefret soylemi veya spam yasaktir.<br>' +
                '&nbsp;&nbsp;2. Baskalarinin kisisel bilgilerini izinsiz paylasma.<br>' +
                '&nbsp;&nbsp;3. Platformu yalnizca yetenek degisimi ve ogrenme icin kullan.<br>' +
                '&nbsp;&nbsp;4. Kural ihlali sureli/suresiz bana yol acabilir (GitHub hesabina bagli).<br>' +
                'Tam metin icin: /terms sayfasina bak.';
        } else if (text === '/help') {
            sysResponse = 'Kullanilabilir komutlar:<br>&nbsp;&nbsp;/clear&nbsp; - terminali temizle<br>&nbsp;&nbsp;/whoami - yetki seviyeni goster<br>&nbsp;&nbsp;/ping&nbsp;&nbsp; - agi test et<br>&nbsp;&nbsp;/omni&nbsp;&nbsp; - kisisel durum panelini goster<br>&nbsp;&nbsp;/mute&nbsp;&nbsp; &lt;isim&gt; &lt;süre&gt; - kullaniciyi sustur (staff)<br>&nbsp;&nbsp;/unmute &lt;isim&gt; - susturmayi kaldir (staff)<br>&nbsp;&nbsp;/block&nbsp; &lt;isim&gt; - kullaniciyi engelle<br>&nbsp;&nbsp;/unblock &lt;isim&gt; - engeli kaldir<br>&nbsp;&nbsp;/ban&nbsp;&nbsp;&nbsp; &lt;isim&gt; [süre gün] - kullaniciyi banla (admin)<br>&nbsp;&nbsp;/unban &lt;isim&gt; - bani kaldir (admin)<br>&nbsp;&nbsp;/report &lt;isim&gt; - kullaniciyi sikayet et<br>&nbsp;&nbsp;/rules&nbsp; - kurallarin ozetini goster<br>&nbsp;&nbsp;/help&nbsp;&nbsp; - bu listeyi goster';
        } else {
            sysResponse = `Bilinmeyen komut: ${text}. (Kullanılabilir: /clear, /whoami, /ping, /omni, /help)`;
        }

        if (sysResponse !== '' && messagesContainer) {
            const cmdHTML = `
            <div class="mb-3 mt-2 border-l-2 border-terminal-accent-2 pl-2 bg-terminal-accent-2/20 py-2 font-mono text-sm">
              <span class="text-terminal-accent-2 font-bold text-xs tracking-widest">[SYS_EXEC]</span>
              <span class="text-terminal-text ml-2">${sysResponse}</span>
            </div>
          `;
            messagesContainer.insertAdjacentHTML('beforeend', cmdHTML);
            messagesContainer.scrollTop = messagesContainer.scrollHeight;
        }

        // Komut çalıştıktan sonra inputu anında temizle
        input.value = '';
    } else if (e.key === 'ArrowUp') {
        if (commandHistory.length === 0) return;
        e.preventDefault();
        historyIndex = Math.max(0, historyIndex - 1);
        input.value = commandHistory[historyIndex] ?? '';
        input.setSelectionRange(input.value.length, input.value.length);
    } else if (e.key === 'ArrowDown') {
        if (commandHistory.length === 0) return;
        e.preventDefault();
        historyIndex = Math.min(commandHistory.length, historyIndex + 1);
        input.value = commandHistory[historyIndex] ?? '';
        input.setSelectionRange(input.value.length, input.value.length);
    }
});

// 2. NORMAL MESAJLAR: Turbo işlemi başarıyla bitirdiğinde formu resmi olarak sıfırla
document.addEventListener('turbo:submit-end', (e) => {
    if (e.target.id !== 'terminal-form') return;
    const input = e.target.querySelector('input[type="text"]');
    if (!input) return;

    const sentValue = input.value.trim();
    if (sentValue !== '') {
        commandHistory.push(sentValue);
        historyIndex = commandHistory.length;
        sessionStorage.setItem(COMMAND_HISTORY_KEY, JSON.stringify(commandHistory));
    }
    input.value = '';
});

document.addEventListener('input', (e) => {
    if (!e.target.matches('#terminal-form input[type="text"]')) return;
    if (!e.target.value.startsWith('/')) {
        subscription.perform('typing', { user: currentUserName, room: getCurrentRoomSlug() });
    }
});

// Ping Animasyonu (Önceki adımdan)
document.addEventListener('turbo:load', () => {
    const pingSensor = document.getElementById('ping-sensor');
    if (pingSensor) {
        setInterval(() => {
            const ping = Math.floor(Math.random() * (24 - 8 + 1)) + 8;
            pingSensor.innerText = ping;
        }, 2500);
    }
});