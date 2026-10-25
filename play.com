<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Froggy Math Adventure</title>
    <style>
        /* ================== CSS VARIABLES & RESET ================== */
        :root {
            --primary: #4CAF50;
            --primary-dark: #388E3C;
            --secondary: #29b6f6;
            --accent: #FFC107;
            --text-dark: #333;
            --text-light: #fff;
            --danger: #ef5350;
            --pad-color: #66bb6a;
            --bg-sky: #e1f5fe;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            user-select: none;
            -webkit-tap-highlight-color: transparent;
        }

        body {
            font-family: 'Comic Sans MS', 'Chalkboard SE', 'Marker Felt', sans-serif;
            background-color: var(--bg-sky);
            color: var(--text-dark);
            overflow: hidden;
            width: 100vw;
            height: 100vh;
        }

        /* ================== GLOBAL UI ================== */
        #app {
            width: 100%;
            height: 100%;
            display: flex;
            flex-direction: column;
            position: relative;
        }

        header {
            position: absolute;
            top: 0; left: 0; right: 0;
            padding: 10px 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            z-index: 100;
            pointer-events: none;
        }

        .header-controls {
            display: flex;
            gap: 10px;
            pointer-events: auto;
        }

        .btn-icon {
            background: rgba(255, 255, 255, 0.8);
            border: 2px solid var(--primary);
            border-radius: 50%;
            width: 45px; height: 45px;
            font-size: 1.2rem;
            cursor: pointer;
            display: flex;
            justify-content: center;
            align-items: center;
            box-shadow: 0 4px 0 var(--primary-dark);
            transition: transform 0.1s, box-shadow 0.1s;
        }
        .btn-icon:active {
            transform: translateY(4px);
            box-shadow: 0 0 0 var(--primary-dark);
        }

        .screen {
            display: none;
            width: 100%;
            height: 100%;
            position: absolute;
            top: 0; left: 0;
            background: linear-gradient(to bottom, var(--bg-sky) 0%, #b3e5fc 100%);
            overflow: hidden;
            z-index: 10;
        }
        .screen.active {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
        }

        .btn {
            background: var(--primary);
            color: white;
            border: none;
            padding: 15px 30px;
            font-size: 1.5rem;
            border-radius: 30px;
            cursor: pointer;
            box-shadow: 0 6px 0 var(--primary-dark);
            font-family: inherit;
            margin: 10px;
            transition: all 0.1s;
            text-transform: uppercase;
            letter-spacing: 1px;
            text-align: center;
        }
        .btn:active {
            transform: translateY(6px);
            box-shadow: 0 0 0 var(--primary-dark);
        }
        .btn-secondary { background: var(--secondary); box-shadow: 0 6px 0 #0288d1; }
        .btn-secondary:active { box-shadow: 0 0 0 #0288d1; }
        
        .title-logo {
            font-size: 4rem;
            color: var(--primary-dark);
            text-shadow: 3px 3px 0 var(--text-light), -1px -1px 0 var(--text-light), 1px -1px 0 var(--text-light), -1px 1px 0 var(--text-light);
            text-align: center;
            margin-bottom: 10px;
            line-height: 1.1;
        }
        .tagline { font-size: 1.5rem; margin-bottom: 30px; color: #555; text-align: center; }

        /* ================== MENUS ================== */
        .cards-container {
            display: flex;
            gap: 20px;
            flex-wrap: wrap;
            justify-content: center;
            max-width: 900px;
        }
        .card {
            background: white;
            border-radius: 20px;
            padding: 20px;
            width: 250px;
            text-align: center;
            box-shadow: 0 8px 15px rgba(0,0,0,0.1);
            cursor: pointer;
            border: 4px solid transparent;
            transition: transform 0.2s;
        }
        .card:hover { transform: scale(1.05); border-color: var(--primary); }
        .card-icon { font-size: 4rem; margin-bottom: 10px; }
        .card-title { font-size: 1.5rem; color: var(--primary-dark); margin-bottom: 10px; }
        .card-desc { font-size: 1rem; color: #666; }

        .settings-panel {
            background: white; padding: 20px; border-radius: 20px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            width: 90%; max-width: 500px;
            text-align: center;
        }
        .settings-group { margin-bottom: 15px; }
        .settings-group h3 { margin-bottom: 10px; color: var(--primary-dark); }
        .choice-btn {
            background: #eee; border: 2px solid #ccc; padding: 10px 15px;
            border-radius: 15px; margin: 5px; font-family: inherit; font-size: 1.1rem; cursor: pointer;
        }
        .choice-btn.selected { background: var(--secondary); color: white; border-color: #0288d1; }

        /* ================== GAME AREA ================== */
        #game-board {
            width: 100%; height: 100%; display: grid; gap: 5px; padding: 60px 10px 10px 10px;
            background: linear-gradient(to bottom, #81d4fa 0%, #29b6f6 100%); /* Water base */
            position: relative;
        }

        /* Water Animation Overlay */
        .water-overlay {
            position: absolute; top: 0; left: 0; width: 100%; height: 100%;
            background: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="100" height="50" opacity="0.1"><path d="M0 25 Q 25 0 50 25 T 100 25" fill="none" stroke="white" stroke-width="2"/></svg>');
            animation: moveWater 4s linear infinite; pointer-events: none; z-index: 0;
        }
        @keyframes moveWater { from { background-position: 0 0; } to { background-position: 100px 0; } }

        .player-area {
            background: rgba(255, 255, 255, 0.2);
            border: 3px solid rgba(255,255,255,0.5);
            border-radius: 20px;
            display: flex; flex-direction: column;
            position: relative; z-index: 1;
            overflow: hidden;
        }

        /* Layouts per mode */
        #game-board.mode-solo { grid-template-columns: 1fr; grid-template-rows: 1fr; padding: 70px 20px 20px 20px; }
        #game-board.mode-duel { grid-template-columns: 1fr 1fr; grid-template-rows: 1fr; }
        #game-board.mode-squad { grid-template-columns: 1fr 1fr; grid-template-rows: 1fr 1fr; }

        @media (max-width: 768px) and (orientation: portrait) {
            #game-board.mode-duel { grid-template-columns: 1fr; grid-template-rows: 1fr 1fr; }
            #game-board.mode-squad { grid-template-columns: 1fr; grid-template-rows: 1fr 1fr 1fr 1fr; }
        }

        .p-header {
            display: flex; justify-content: space-between; align-items: center;
            background: rgba(255,255,255,0.8); padding: 5px 15px;
            border-bottom: 2px solid rgba(0,0,0,0.1);
            font-size: 1.1rem;
        }
        .p-score { font-weight: bold; color: var(--accent); text-shadow: 1px 1px 0 #000; font-size: 1.3rem;}

        .scene {
            flex: 1; position: relative; display: flex; flex-direction: column;
            align-items: center; justify-content: space-between; padding: 10px;
        }
        
        .question-box {
            background: white; border: 4px solid var(--primary); border-radius: 20px;
            padding: 10px 20px; font-size: 2rem; font-weight: bold; color: var(--text-dark);
            box-shadow: 0 4px 10px rgba(0,0,0,0.2); z-index: 5; text-align: center;
            min-width: 150px;
        }

        .pond {
            flex: 1; width: 100%; position: relative;
            display: flex; flex-direction: column; justify-content: center; align-items: center;
            gap: 20px;
        }

        /* Lilypads */
        .pad-row {
            display: flex; justify-content: space-around; width: 100%; margin-bottom: 30px; z-index: 2;
        }
        .lilypad {
            width: 130px; height: 55px; background: var(--pad-color);
            border-radius: 50%; position: relative;
            box-shadow: inset -5px -5px 10px rgba(0,0,0,0.2), 0 5px 0 #2e7d32;
            display: flex; justify-content: center; align-items: center;
            font-size: 2.2rem; font-weight: bold; color: white;
            text-shadow: 1px 1px 0 #000;
            cursor: pointer; transition: transform 0.2s;
        }
        .lilypad::after { /* leaf cut */
            content: ''; position: absolute; right: 0; top: 20px; width: 25px; height: 25px;
            background: transparent; border-radius: 50%; box-shadow: 10px -10px 0 var(--secondary);
            clip-path: circle(50% at right); opacity: 0.5;
        }
        .pad-answer:hover { transform: scale(1.1); }
        .pad-start { width: 150px; height: 65px; cursor: default; }

        /* Frog */
        .frog {
            font-size: 4.5rem; position: absolute; z-index: 10;
            transition: transform 0.1s; filter: drop-shadow(0 5px 5px rgba(0,0,0,0.4));
        }

        /* Feedback / Animations */
        .feedback {
            position: absolute; top: 30%; left: 50%; transform: translate(-50%, -50%);
            font-size: 2.5rem; font-weight: bold; z-index: 20; opacity: 0; pointer-events: none;
            text-shadow: 2px 2px 0 #fff, -2px -2px 0 #fff;
        }
        @keyframes floatUp { 0% { opacity: 1; transform: translate(-50%, -50%) scale(0.5); } 50% { transform: translate(-50%, -80%) scale(1.2); } 100% { opacity: 0; transform: translate(-50%, -100%) scale(1); } }
        
        .splash {
            position: absolute; font-size: 3rem; opacity: 0; pointer-events: none; z-index: 15;
        }
        @keyframes splashAnim { 0% { opacity: 1; transform: scale(0.5) translateY(20px); } 50% { transform: scale(1.5) translateY(-10px); } 100% { opacity: 0; transform: scale(2) translateY(10px); } }

        /* Results Screen */
        .result-container {
            background: white; border-radius: 20px; padding: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2); width: 90%; max-width: 600px;
            text-align: center; max-height: 90vh; overflow-y: auto;
        }
        .result-row {
            display: flex; justify-content: space-between; align-items: center;
            background: #f5f5f5; padding: 10px 20px; margin-bottom: 10px; border-radius: 10px;
            border-left: 5px solid var(--primary);
        }
        .result-rank { font-size: 1.5rem; font-weight: bold; color: var(--primary-dark); }
        .result-name { font-size: 1.2rem; flex: 1; text-align: left; margin-left: 15px; }
        .result-score { font-size: 1.5rem; font-weight: bold; color: var(--accent); }

        /* Riak/Cipratan air di daun teratai (Sekarang untuk semua mode) */
        .lilypad::before {
            content: '';
            position: absolute;
            top: 50%; left: 50%;
            width: 100%; height: 100%;
            border: 2px solid rgba(255, 255, 255, 0.7);
            border-radius: 50%;
            transform: translate(-50%, -50%);
            animation: leafRipple 2s infinite ease-out;
            pointer-events: none;
            z-index: -1;
        }
        @keyframes leafRipple {
            0% { width: 100%; height: 100%; opacity: 1; }
            100% { width: 160%; height: 160%; opacity: 0; }
        }

        /* Rintik Hujan */
        .rain-overlay {
            position: absolute; top: 0; left: 0; width: 100%; height: 100%;
            background: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="40" height="80" opacity="0.3"><line x1="20" y1="0" x2="0" y2="40" stroke="%23ffffff" stroke-width="1.5"/></svg>');
            animation: rainFall 0.4s linear infinite;
            pointer-events: none; z-index: 30;
        }
        @keyframes rainFall {
            0% { background-position: 0 0; }
            100% { background-position: -40px 80px; }
        }

        /* Rumput Bergoyang (Global - Semua Mode) */
        .global-grass-area {
            position: absolute;
            bottom: -5px;
            left: -10px;
            width: calc(100% + 20px);
            height: 60px;
            display: flex;
            justify-content: space-around;
            align-items: flex-end;
            z-index: 40;
            pointer-events: none;
            overflow: hidden;
        }
        .grass-blade {
            width: 12px;
            height: 40px;
            background: linear-gradient(to top, #1b5e20, #4caf50);
            border-radius: 50% 50% 0 0;
            transform-origin: bottom center;
            animation: sway 2.5s ease-in-out infinite alternate;
            box-shadow: -2px 0 5px rgba(0,0,0,0.3);
        }
        .grass-blade:nth-child(even) { 
            animation-duration: 3s; 
            height: 55px; 
            background: linear-gradient(to top, #2e7d32, #66bb6a); 
        }
        .grass-blade:nth-child(3n) { 
            animation-duration: 2.2s; 
            height: 35px; 
        }
        @keyframes sway {
            0% { transform: rotate(-20deg); }
            100% { transform: rotate(20deg); }
        }

        /* Responsive Tweaks */
        @media (max-width: 600px) {
            .title-logo { font-size: 2.5rem; }
            .lilypad { width: 90px; height: 45px; font-size: 1.5rem; }
            .pad-start { width: 110px; height: 50px; }
            .frog { font-size: 3.5rem; }
            .question-box { font-size: 1.5rem; padding: 5px 10px; }
            .pad-row { margin-bottom: 15px; }
        }
    </style>
</head>
<body>
    <div id="app">
        <!-- GLOBAL HEADER -->
        <header>
            <div style="pointer-events: auto;">
                <div class="btn-icon" id="btn-home" style="display:none;" onclick="navTo('main-menu')">🏠</div>
            </div>
            <div class="header-controls">
                <div class="btn-icon" id="btn-audio" onclick="toggleAudio()">🔊</div>
                <div class="btn-icon" id="btn-fs" onclick="toggleFullscreen()">⛶</div>
            </div>
        </header>

        <!-- MAIN MENU -->
        <div id="screen-main-menu" class="screen active">
            <h1 class="title-logo">🐸 FROGGY<br>MATH ADVENTURE</h1>
            <p class="tagline">Lompat, Jawab, dan Jadilah Katak Matematika Hebat!</p>
            <button class="btn" onclick="navTo('mode-selection'); playSound('jump')">Mulai Bermain</button>
            <button class="btn btn-secondary" onclick="navTo('instructions'); playSound('jump')">Petunjuk</button>
        </div>

        <!-- INSTRUCTIONS MENU (Replaced alert() here) -->
        <div id="screen-instructions" class="screen">
            <div class="settings-panel">
                <h2 style="margin-bottom: 20px; color:var(--primary-dark);">Petunjuk Bermain</h2>
                <div style="text-align: left; margin-bottom: 20px; font-size: 1.1rem; line-height: 1.6;">
                    <p>🐸 <strong>1.</strong> Pilih jawaban yang benar untuk melompat ke daun selanjutnya.</p>
                    <p>⭐ <strong>2.</strong> Jika benar, katak melompat dan skor bertambah.</p>
                    <p>🌧️ <strong>3.</strong> Jika salah, katak jatuh dan soal akan diganti.</p>
                    <p>🏆 <strong>4.</strong> Kumpulkan skor tertinggi dan jadilah pemenang!</p>
                </div>
                <button class="btn btn-secondary" style="width:100%;" onclick="navTo('main-menu'); playSound('jump')">Kembali</button>
            </div>
        </div>

        <!-- MODE SELECTION -->
        <div id="screen-mode-selection" class="screen">
            <h2 style="margin-bottom: 20px; font-size: 2rem; color:var(--primary-dark);">Pilih Mode Permainan</h2>
            <div class="cards-container">
                <div class="card" onclick="selectMode(1)">
                    <div class="card-icon">🐸</div>
                    <div class="card-title">SOLO MODE</div>
                    <div class="card-desc">Bermain sendiri dan kumpulkan skor tertinggi. (1 Pemain)</div>
                </div>
                <div class="card" onclick="selectMode(2)">
                    <div class="card-icon">🐸🐸</div>
                    <div class="card-title">DUEL MODE</div>
                    <div class="card-desc">Tantang temanmu dalam adu cepat. (2 Pemain)</div>
                </div>
                <div class="card" onclick="selectMode(4)">
                    <div class="card-icon">🐸🐸🐸🐸</div>
                    <div class="card-title">SQUAD MODE</div>
                    <div class="card-desc">Bermain bersama meraih skor tertinggi. (4 Pemain)</div>
                </div>
            </div>
            <button class="btn btn-secondary" style="margin-top:30px;" onclick="navTo('main-menu')">Kembali</button>
        </div>

        <!-- SETTINGS SELECTION -->
        <div id="screen-settings" class="screen">
            <div class="settings-panel">
                <h2 style="margin-bottom: 20px; color:var(--primary-dark);">Pengaturan Permainan</h2>
                
                <div class="settings-group">
                    <h3>Materi</h3>
                    <button class="choice-btn setting-materi" data-val="perkalian" onclick="setOpt('materi', 'perkalian')">Perkalian</button>
                    <button class="choice-btn setting-materi" data-val="pembagian" onclick="setOpt('materi', 'pembagian')">Pembagian</button>
                    <button class="choice-btn setting-materi selected" data-val="campuran" onclick="setOpt('materi', 'campuran')">Campuran</button>
                </div>

                <div class="settings-group">
                    <h3>Tingkat Kesulitan</h3>
                    <button class="choice-btn setting-level selected" data-val="mudah" onclick="setOpt('level', 'mudah')">Mudah</button>
                    <button class="choice-btn setting-level" data-val="sedang" onclick="setOpt('level', 'sedang')">Sedang</button>
                    <button class="choice-btn setting-level" data-val="tantangan" onclick="setOpt('level', 'tantangan')">Tantangan</button>
                </div>

                <div class="settings-group">
                    <h3>Jumlah Soal</h3>
                    <button class="choice-btn setting-soal selected" data-val="10" onclick="setOpt('soal', 10)">10</button>
                    <button class="choice-btn setting-soal" data-val="15" onclick="setOpt('soal', 15)">15</button>
                    <button class="choice-btn setting-soal" data-val="20" onclick="setOpt('soal', 20)">20</button>
                </div>

                <button class="btn" style="width:100%; margin: 20px 0 0 0;" onclick="startGame()">Mulai Game</button>
                <button class="btn btn-secondary" style="width:100%; margin: 10px 0 0 0; padding:10px;" onclick="navTo('mode-selection')">Kembali</button>
            </div>
        </div>

        <!-- GAME AREA -->
        <div id="screen-game" class="screen">
            <div class="water-overlay"></div>
            <div class="rain-overlay"></div>
            <div id="game-board">
                <!-- Player areas injected by JS -->
            </div>
            <div class="global-grass-area" id="grass-container"></div>
        </div>

        <!-- RESULTS -->
        <div id="screen-result" class="screen">
            <div class="result-container" id="result-content">
                <!-- Injected by JS -->
            </div>
            <div style="margin-top: 20px;">
                <button class="btn" onclick="startGame()">Main Lagi</button>
                <button class="btn btn-secondary" onclick="navTo('main-menu')">Menu Utama</button>
            </div>
        </div>
    </div>

    <script>
        /* ================== AUDIO SYSTEM (Web Audio API) ================== */
        const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
        let audioEnabled = true;

        function playTone(freq, type, duration, vol=0.1) {
            if (!audioEnabled || audioCtx.state === 'suspended') return;
            const osc = audioCtx.createOscillator();
            const gain = audioCtx.createGain();
            osc.type = type;
            osc.frequency.setValueAtTime(freq, audioCtx.currentTime);
            
            gain.gain.setValueAtTime(vol, audioCtx.currentTime);
            gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + duration);
            
            osc.connect(gain);
            gain.connect(audioCtx.destination);
            osc.start();
            osc.stop(audioCtx.currentTime + duration);
        }

        function playSound(type) {
            if(audioCtx.state === 'suspended') audioCtx.resume();
            if(!audioEnabled) return;
            
            if(type === 'jump') {
                const osc = audioCtx.createOscillator();
                const gain = audioCtx.createGain();
                osc.type = 'sine';
                osc.frequency.setValueAtTime(300, audioCtx.currentTime);
                osc.frequency.exponentialRampToValueAtTime(600, audioCtx.currentTime + 0.2);
                gain.gain.setValueAtTime(0.1, audioCtx.currentTime);
                gain.gain.linearRampToValueAtTime(0, audioCtx.currentTime + 0.2);
                osc.connect(gain); gain.connect(audioCtx.destination);
                osc.start(); osc.stop(audioCtx.currentTime + 0.2);
            } else if (type === 'correct') {
                playTone(523.25, 'square', 0.1, 0.05); // C5
                setTimeout(() => playTone(659.25, 'square', 0.1, 0.05), 100); // E5
                setTimeout(() => playTone(783.99, 'square', 0.2, 0.05), 200); // G5
            } else if (type === 'wrong') {
                const osc = audioCtx.createOscillator();
                const gain = audioCtx.createGain();
                osc.type = 'sawtooth';
                osc.frequency.setValueAtTime(300, audioCtx.currentTime);
                osc.frequency.exponentialRampToValueAtTime(100, audioCtx.currentTime + 0.4);
                gain.gain.setValueAtTime(0.1, audioCtx.currentTime);
                gain.gain.linearRampToValueAtTime(0, audioCtx.currentTime + 0.4);
                osc.connect(gain); gain.connect(audioCtx.destination);
                osc.start(); osc.stop(audioCtx.currentTime + 0.4);
            } else if (type === 'win') {
                playTone(440, 'sine', 0.1); setTimeout(() => playTone(554, 'sine', 0.1), 150);
                setTimeout(() => playTone(659, 'sine', 0.3), 300);
            }
        }

        function toggleAudio() {
            audioEnabled = !audioEnabled;
            document.getElementById('btn-audio').innerText = audioEnabled ? '🔊' : '🔇';
            if(audioEnabled && audioCtx.state === 'suspended') audioCtx.resume();
        }

        /* ================== FULLSCREEN ================== */
        function toggleFullscreen() {
            if (!document.fullscreenElement) {
                document.documentElement.requestFullscreen().catch(err => console.log(err));
            } else {
                if (document.exitFullscreen) document.exitFullscreen();
            }
        }

        /* ================== GAME LOGIC ================== */
        const state = {
            mode: 1, // 1, 2, 4
            config: { materi: 'campuran', level: 'mudah', soal: 10 },
            players: [],
            questionsBank: [], // shared questions to ensure fairness
            gameActive: false
        };

        // Navigation
        function navTo(screenId) {
            document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
            document.getElementById('screen-' + screenId).classList.add('active');
            document.getElementById('btn-home').style.display = (screenId === 'main-menu') ? 'none' : 'flex';
            if(audioCtx.state === 'suspended') audioCtx.resume();
        }

        function selectMode(m) {
            state.mode = m;
            playSound('jump');
            navTo('settings');
        }

        function setOpt(type, val) {
            state.config[type] = val;
            document.querySelectorAll(`.setting-${type}`).forEach(b => {
                b.classList.toggle('selected', b.dataset.val == val);
            });
            playSound('jump');
        }

        // Questions Generation
        function generateQuestionsArray() {
            let arr = [];
            for (let i = 0; i < state.config.soal; i++) {
                let isMultiply = state.config.materi === 'perkalian' ? true : 
                                 state.config.materi === 'pembagian' ? false : 
                                 Math.random() > 0.5;
                
                let num1, num2, ans, text;
                
                if (state.config.level === 'mudah') {
                    num1 = Math.floor(Math.random() * 5) + 1; // 1-5
                    num2 = Math.floor(Math.random() * 5) + 1; // 1-5
                } else if (state.config.level === 'sedang') {
                    num1 = Math.floor(Math.random() * 9) + 2; // 2-10
                    num2 = Math.floor(Math.random() * 5) + 2; // 2-6
                } else { // tantangan
                    num1 = Math.floor(Math.random() * 9) + 2; // 2-10
                    num2 = Math.floor(Math.random() * 9) + 2; // 2-10
                }

                if (isMultiply) {
                    ans = num1 * num2;
                    text = `${num1} × ${num2}`;
                } else {
                    ans = num1;
                    let dividend = num1 * num2;
                    text = `${dividend} ÷ ${num2}`;
                }

                // Generate distractors
                let options = [ans];
                while(options.length < 4) {
                    let offset = Math.floor(Math.random() * 10) - 5;
                    let wrong = ans + offset;
                    if (wrong > 0 && !options.includes(wrong)) options.push(wrong);
                }
                options.sort(() => Math.random() - 0.5);

                arr.push({ text, options, answer: ans });
            }
            return arr;
        }

        // Initialize Game
        function startGame() {
            state.questionsBank = generateQuestionsArray();
            state.players = [];
            state.gameActive = true;

            const board = document.getElementById('game-board');
            board.innerHTML = '';
            board.className = '';
            board.classList.add(state.mode === 1 ? 'mode-solo' : state.mode === 2 ? 'mode-duel' : 'mode-squad');

            for (let i = 0; i < state.mode; i++) {
                state.players.push({
                    id: i,
                    name: `PLAYER ${i+1}`,
                    score: 0,
                    qIndex: 0,
                    correct: 0,
                    streak: 0,
                    locked: false
                });

                // Inject Player UI
                const pArea = document.createElement('div');
                pArea.className = 'player-area';
                pArea.id = `player-area-${i}`;
                pArea.innerHTML = `
                    <div class="p-header">
                        <span>${state.players[i].name} | Soal <span id="q-counter-${i}">1</span>/${state.config.soal}</span>
                        <span class="p-score" id="score-${i}">0</span>
                    </div>
                    <div class="scene">
                        <div class="question-box" id="q-box-${i}"></div>
                        <div class="pond">
                            <div class="pad-row" id="pad-options-${i}">
                                <!-- options injected here -->
                            </div>
                            <div class="pad-row" style="justify-content: center;">
                                <div class="lilypad pad-start">
                                    <div class="frog" id="frog-${i}">🐸</div>
                                </div>
                            </div>
                            <div class="feedback" id="feedback-${i}"></div>
                            <div class="splash" id="splash-${i}">💦</div>
                        </div>
                    </div>
                `;
                board.appendChild(pArea);
                renderQuestion(i);
            }
            
            navTo('game');
        }

        function renderQuestion(pId) {
            const player = state.players[pId];
            if(player.qIndex >= state.config.soal) {
                checkGameEnd();
                return;
            }

            const q = state.questionsBank[player.qIndex];
            document.getElementById(`q-counter-${pId}`).innerText = player.qIndex + 1;
            document.getElementById(`q-box-${pId}`).innerText = q.text;
            
            const optContainer = document.getElementById(`pad-options-${pId}`);
            optContainer.innerHTML = '';
            
            q.options.forEach((opt, idx) => {
                const pad = document.createElement('div');
                pad.className = 'lilypad pad-answer';
                pad.innerText = opt;
                pad.onclick = () => handleAnswer(pId, opt, pad);
                optContainer.appendChild(pad);
            });

            // Reset frog pos
            const frog = document.getElementById(`frog-${pId}`);
            frog.style.transform = 'translate(0, 0) scale(1) rotate(0deg)';
            frog.style.opacity = '1';
            
            player.locked = false;
        }

        function handleAnswer(pId, selectedOpt, padElem) {
            const player = state.players[pId];
            if (player.locked || !state.gameActive) return;
            player.locked = true;

            const q = state.questionsBank[player.qIndex];
            const isCorrect = (selectedOpt === q.answer);
            
            const frog = document.getElementById(`frog-${pId}`);
            const feedback = document.getElementById(`feedback-${pId}`);
            const splash = document.getElementById(`splash-${pId}`);
            
            // Calculate distance for jump
            const frogRect = frog.getBoundingClientRect();
            const padRect = padElem.getBoundingClientRect();
            const dx = padRect.left - frogRect.left + (padRect.width/2 - frogRect.width/2);
            const dy = padRect.top - frogRect.top - 10; // slightly above

            if (isCorrect) {
                // Correct logic
                player.correct++;
                player.streak++;
                player.score += 10;
                if (player.streak > 0 && player.streak % 3 === 0) player.score += 5; // bonus
                
                playSound('correct');
                feedback.innerText = "Bagus! ⭐";
                feedback.style.color = "#FFC107";
                feedback.style.animation = 'floatUp 1s forwards';

                // Jump animation using JS API
                frog.animate([
                    { transform: 'translate(0,0)' },
                    { transform: `translate(${dx/2}px, ${dy - 50}px) scale(1.2)` },
                    { transform: `translate(${dx}px, ${dy}px) scale(1)` }
                ], { duration: 400, fill: 'forwards', easing: 'ease-in-out' });

            } else {
                // Wrong logic
                player.streak = 0;
                playSound('wrong');
                feedback.innerText = "Ups! 🌧️";
                feedback.style.color = "var(--danger)";
                feedback.style.animation = 'floatUp 1s forwards';

                // Fall animation
                frog.animate([
                    { transform: 'translate(0,0)' },
                    { transform: `translate(${dx/2}px, ${dy - 20}px) rotate(45deg)` },
                    { transform: `translate(${dx}px, ${dy + 40}px) scale(0.5) rotate(90deg)`, opacity: 0 }
                ], { duration: 500, fill: 'forwards', easing: 'ease-in' });
                
                setTimeout(() => {
                    splash.style.left = `calc(50% + ${dx}px)`;
                    splash.style.top = `calc(100% - 100px)`; // approximate
                    splash.style.animation = 'splashAnim 0.6s forwards';
                }, 400);
            }

            document.getElementById(`score-${pId}`).innerText = player.score;

            // Wait, clear animations, next question
            setTimeout(() => {
                feedback.style.animation = 'none';
                splash.style.animation = 'none';
                player.qIndex++;
                renderQuestion(pId);
            }, 1200);
        }

        function checkGameEnd() {
            // Check if all finished
            if (state.players.every(p => p.qIndex >= state.config.soal)) {
                state.gameActive = false;
                showResultScreen();
            }
        }

        function showResultScreen() {
            playSound('win');
            const resContainer = document.getElementById('result-content');
            resContainer.innerHTML = `<h1 style="color:var(--primary-dark); margin-bottom:20px;">Permainan Selesai! 🎉</h1>`;
            
            let sorted = [...state.players].sort((a, b) => b.score - a.score || b.correct - a.correct);
            
            sorted.forEach((p, idx) => {
                const acc = Math.round((p.correct / state.config.soal) * 100);
                let medal = idx === 0 ? '🏆' : (idx===1 ? '🥈' : (idx===2 ? '🥉' : '⭐'));
                
                resContainer.innerHTML += `
                    <div class="result-row">
                        <div class="result-rank">${medal} #${idx+1}</div>
                        <div class="result-name">
                            <strong>${p.name}</strong><br>
                            <span style="font-size:0.9rem; color:#666;">Benar: ${p.correct}/${state.config.soal} (${acc}%)</span>
                        </div>
                        <div class="result-score">${p.score} pt</div>
                    </div>
                `;
            });
            
            navTo('result');
        }

        // Global Event for initialization gesture (Audio context)
        document.body.addEventListener('click', () => {
            if(audioCtx.state === 'suspended') audioCtx.resume();
        }, { once: true });

        // Initialize Global Grass
        document.addEventListener('DOMContentLoaded', () => {
            const grassCont = document.getElementById('grass-container');
            if(grassCont) {
                let html = '';
                for(let i = 0; i < 80; i++) { // Jumlah rumput diperbanyak untuk lebar penuh layar
                    html += '<div class="grass-blade"></div>';
                }
                grassCont.innerHTML = html;
            }
        });

    </script>
</body>
</html>
