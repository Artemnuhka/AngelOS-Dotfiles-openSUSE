.pragma library

// What the corner helper says (services/Angel.qml). Tips come in pairs
// [ru, en, settings page]; jokes are written per language, not translated:
// Russian ones are grey everyday humour with a dash of black, English ones
// their own thing. The demon jokes are cheeky, never explicit.

const tips = [
    ["В настройках можно искать своими словами: «сделать крупнее», «звук потише»… Попробуй!", "You can search settings in your own words: “bigger”, “quieter”… Try it!", "home"],
    ["ПКМ по рабочему столу → Вид — там живут виджеты: часы, музыка, cava ♡", "Right-click the desktop → View: that's where widgets live ♡", "widgets"],
    ["Виджеты можно увеличить: зажми Ctrl и покрути колёсико над ними.", "Widgets grow: hold Ctrl and scroll over one.", "widgets"],
    ["Двойной клик по заголовку виджета — режим правки, там появятся крестики.", "Double-click a widget's title bar for edit mode, with little × buttons.", "widgets"],
    ["Хочешь, чтобы обои менялись красиво? Там есть сердечко, телевизор и даже плавление, как в DOOM!", "Want a fancy wallpaper change? There's a heart, an old TV and even a DOOM melt!", "wallpaper"],
    ["Обои можно поставить на каждый рабочий стол свои — выбери «Куда» на странице обоев.", "Every workspace can have its own wallpaper: pick “Where” on the wallpaper page.", "wallpaper"],
    ["Mod+Shift+S — скриншот области, он сразу окажется в буфере.", "Mod+Shift+S takes a region screenshot straight to the clipboard.", "capture"],
    ["Mod+Shift+R записывает видео с области экрана. Нажми ещё раз — стоп.", "Mod+Shift+R records a region of the screen. Press it again to stop.", "capture"],
    ["У выделения скриншота есть скины: верёвочки, окошко и стрим NGO.", "The screenshot selector has skins: ropes, a window and an NGO stream.", "capture"],
    ["Любое сочетание клавиш можно поменять — даже для своих программ.", "Any shortcut can be changed, even for your own apps.", "shortcuts"],
    ["Mod+Shift+Esc показывает все горячие клавиши сразу. Шпаргалка ♡", "Mod+Shift+Esc shows every shortcut at once. A cheat sheet ♡", "shortcuts"],
    ["Средняя кнопка мыши по окну на панели закрывает его, как вкладку в браузере.", "Middle-click a window on the taskbar to close it, like a browser tab.", "windows"],
    ["ПКМ по кнопке окна на панели — меню окна: закрыть, развернуть, отправить на другой стол.", "Right-click a window button on the taskbar for the window menu: close, maximize, move.", "windows"],
    ["Mod+V — история буфера обмена. Там и картинки, и текст.", "Mod+V opens the clipboard history, pictures included.", ""],
    ["Mod+Space — поиск программ. Начни с «>», и это будет команда для терминала.", "Mod+Space finds apps. Start with “>” to run a command.", ""],
    ["Короткое нажатие Win открывает «Пуск», как в Windows.", "A short tap of the Win key opens Start, like on Windows.", "bar"],
    ["«Пуск» бывает трёх видов: список как в Win98, плитки как в Win11 и на весь экран, как в телефоне.", "Start comes in three styles: a Win98 list, Win11 tiles and a phone-like full screen grid.", "bar"],
    ["Панель бывает снизу, сверху или маленьким островом — страница «Панель».", "The bar can sit at the bottom, on top or float as an island: see the Bar page.", "bar"],
    ["Mod+Alt+Y включает текст песни прямо на панели. Караоке!", "Mod+Alt+Y shows song lyrics right in the bar. Karaoke time!", "lyrics"],
    ["Mod+Alt+T переключает светлую и тёмную тему.", "Mod+Alt+T flips between the light and the dark theme.", "appearance"],
    ["Если выбрать цвета «из обоев», тема сама подстроится под картинку.", "Pick colours “from the wallpaper” and the theme follows the picture.", "appearance"],
    ["Мелко? На главной настроек есть кнопки «Крупнее» и «Мельче».", "Too small? The settings home has “Bigger” and “Smaller” buttons.", "home"],
    ["Пиксельные шрифты ставятся одним нажатием — есть готовые наборы.", "Pixel fonts install in one click, and there are ready-made sets.", "fonts"],
    ["Пиксельный курсор можно поставить везде сразу: niri, GTK, Steam, Flatpak.", "A pixel cursor can go everywhere at once: niri, GTK, Steam, Flatpak.", "cursor"],
    ["Есть заставка с ASCII-артом: включается сама, если долго ничего не трогать.", "There's an ASCII-art idle screen that starts when you leave the computer alone.", "lock"],
    ["На экране блокировки сердечки реагируют на пароль. Ошибёшься — сердечко разобьётся.", "On the lock screen the hearts react to your password. Miss it and one breaks.", "lock"],
    ["Рабочим столам можно дать имена: «работа», «игры», «не смотреть».", "Workspaces can have names: “work”, “games”, “do not look”.", "workspaces"],
    ["Когда переключаешь рабочий стол, сердечки на панели прыгают — анимацию можно выбрать.", "The hearts on the bar hop when you switch workspaces; pick how they move.", "workspaces"],
    ["Mod+Tab — обзор всех рабочих столов сверху.", "Mod+Tab shows every workspace from above.", ""],
    ["Плагины добавляют виджеты, пункты меню и игры. Даже osu! есть.", "Plugins add widgets, menu items and games. There's even osu!.", "plugins"],
    ["Геймпад можно проверить прямо в настройках: всё, что нажимаешь, подсвечивается.", "Test a gamepad right in Settings: everything you press lights up.", "gamepad"],
    ["Чем открывать ссылки и файлы — на странице «По умолчанию».", "Which apps open links and files: the Default apps page.", "defaults"],
    ["Во время стрима я прячусь сама: OBS скажет мне, что ты в эфире.", "When you stream I hide by myself: OBS tells me you're live.", "y2k"],
    ["Есть звуки из NEEDY GIRL OVERDOSE! Y2K → Звуки → набор «Overdose».", "There are NEEDY GIRL OVERDOSE sounds! Y2K → Sounds → the “Overdose” pack.", "y2k"],
    ["Поменял настройку и пожалел? Кнопка «Отменить» сверху в настройках вернёт как было.", "Changed a setting and regret it? “Undo” at the top of Settings puts it back.", "home"],
    ["Если что-то сломалось, `angelos report` в терминале соберёт отчёт для issue на GitHub.", "If something breaks, `angelos report` in a terminal packs a report for a GitHub issue.", ""],
    ["Меня можно схватить мышкой… Только не скидывай вниз, ладно? Там ад, и оттуда придёт она.", "You can grab me with the mouse… just don't throw me down, okay? That's hell, and she comes out of it.", ""],
    ["Не забывай пить водичку и моргать ♡", "Remember to drink water and blink ♡", ""],
    ["Встань, потянись. Я подожду, я вечная.", "Stand up and stretch. I'll wait, I'm eternal.", ""],
    ["Если что-то сломалось — в «Эксперт» есть всё-всё. Но я верю, что всё хорошо!", "If something breaks, Expert mode has everything. But I believe it's all fine!", ""]
];

// said once, the first time a settings page opens
const pageTips = {
    "wallpaper": ["Кликни картинку — и она на столе. Переход можно выбрать ниже, моё любимое — сердечко.", "Click a picture and it's on the desk. Pick a transition below; the heart is my favourite."],
    "widgets": ["Виджеты таскаются за заголовок. Ctrl + колёсико — размер ♡", "Drag widgets by the title bar. Ctrl + wheel changes their size ♡"],
    "bar": ["Попробуй стиль «остров» — панель станет маленькой и будет парить.", "Try the “island” style: the bar shrinks and floats."],
    "workspaces": ["Нажимай варианты — внизу сразу покажется, как это выглядит.", "Click the options: a preview shows right below."],
    "lock": ["Здесь и заставка с ASCII-артом. Её можно запустить и вручную.", "The ASCII idle screen lives here too; you can start it by hand."],
    "fonts": ["Шрифты с пометкой скачаются сами, ничего искать не надо.", "Marked fonts download themselves, no hunting needed."],
    "cursor": ["Курсор «Glitter» блестит! Это я его заколдовала.", "The “Glitter” cursor sparkles! I enchanted it."],
    "capture": ["Скины меняют рамку выделения — посмотри «стрим», он как в NGO.", "Skins change the selection frame. The “stream” one is straight out of NGO."],
    "shortcuts": ["Нажми на сочетание — и просто нажми новое. Я проверю, чтобы не было конфликтов.", "Click a shortcut and press a new one. I'll check it doesn't clash."],
    "plugins": ["Плагины живут в ~/.config/angelos/plugins — можно написать свой.", "Plugins live in ~/.config/angelos/plugins. You can write your own."],
    "y2k": ["Это моя страница! Тут всё про меня… и про неё. Давай без неё, ладно?", "This is my page! It's all about me… and her. Let's keep her out of it, okay?"],
    "sound": ["Тут только то, что ты трогаешь сам — маршрутизацию пульта я не трогаю.", "Only what you touch changes here; your audio routing is left alone."],
    "monitor": ["«Применить» — попробовать, «Сохранить» — насовсем.", "“Apply” to try it, “Save” to keep it."],
    "updates": ["Обновления приходят из репозитория, откуда ты меня поставил.", "Updates come from the repository you installed me from."],
    "appearance": ["Схема «из обоев» подбирает цвета под картинку. Очень красиво с пиксель-артом.", "The “from wallpaper” scheme picks colours from the picture. Lovely with pixel art."]
};

const jokesRu = [
    "Знаешь, чем ангел отличается от твоего бэкапа? Ангел хотя бы иногда существует.",
    "На небе я работала в техподдержке. Там всем советуют перезагрузиться. Только перезагружаются там… по-другому.",
    "Понедельник — это когда даже у ангела нимб садится до 15%.",
    "Мне сказали быть светом в твоей жизни. Но ты включил тёмную тему, так что я просто стою рядом.",
    "Я могла бы сказать, что всё будет хорошо. Но я видела твою папку «Загрузки».",
    "В раю нет багов. Там вообще ничего нет, кроме облаков и очереди как в МФЦ.",
    "Говорят, у каждого есть ангел-хранитель. Твой — это я. Мы оба понимаем, что это многое объясняет.",
    "Жизнь как Linux: всё можно настроить, но сначала три часа читаешь форум, где тебе отвечают «гугли».",
    "Ноябрь, серое небо, ты за компом, чай остыл. Всё правильно, жизнь удалась.",
    "Я храню тебя от бед. От кредитов не храню — это не моя юрисдикция.",
    "Не переживай из-за ошибок. Все когда-то удаляли не ту папку. Некоторые — через sudo.",
    "Я бы помолилась за твой билд, но туда даже чудо не компилируется.",
    "Твоя оперативка — как мои крылья: вроде есть, а браузер всё равно всё забрал.",
    "Темнее всего перед рассветом. И перед обновлением драйверов NVIDIA.",
    "В чистилище не больно. Там просто вечно ставится обновление Windows: «Не выключайте компьютер».",
    "Я верю в тебя. Это моя работа, мне за неё даже не платят.",
    "Знаешь, почему ангелы не пьют кофе? Вечность и так тянется.",
    "Спи побольше. На том свете выспишься, конечно, но там подушки жёсткие.",
    "Если долго смотреть в терминал, терминал тоже начинает смотреть в тебя. А потом просит пароль.",
    "Будь как облако: ни за что не отвечай и выгляди мило. Нет, это не про облачные сервисы."
];

const jokesEn = [
    "I was going to tell you a UDP joke, but you might not get it. That's fine, heaven doesn't do acknowledgements either.",
    "They said I'd be your guardian angel. Nobody mentioned the forty browser tabs.",
    "Every time a laptop fan spins up, an angel gets her wings. You've been very generous today.",
    "Heaven has no bugs. Mostly because nobody's allowed to deploy on a Friday.",
    "Remember: it's only a mistake if it reaches production. Or the afterlife.",
    "Why did the angel quit tech support? Too many people asking her to turn their lives off and on again.",
    "Drink some water. You're basically a very anxious houseplant.",
    "I'd pray for your code, but I think it's past that stage.",
    "Guardian angel tip: backups are like prayers. Nobody makes them until it's too late.",
    "My halo runs on five volts and good intentions. Mostly the volts.",
    "Cheer up! Somewhere a printer is jammed, and it isn't yours.",
    "I asked the cloud for a sign. It said “503 Service Unavailable”.",
    "You're doing great. The bar is low, but you're definitely above it.",
    "Dark mode protects your eyes. Nothing protects you from your own commit messages.",
    "Fun fact: “it works on my machine” is carved on a lot of tombstones.",
    "Life's short. Your shell history isn't. Maybe tidy that up before anyone reads it at the funeral.",
    "In heaven every day is a Sunday. Down here it's Monday with extra meetings.",
    "I tried to sign in to the afterlife. It wanted a password with a capital letter, a number and your soul."
];

const demonJokesRu = [
    "Ого, сколько вкладок открыто. Любишь, когда много всего и сразу?",
    "Вставь флешку. Не спрашивай зачем, я просто проверяю, как у тебя с портами.",
    "Кулер так пыхтит… Это ты на меня так реагируешь или на браузер?",
    "У меня рога, у тебя root. Чувствуешь напряжение?",
    "Давай без прелюдий: sudo — и поехали.",
    "Мягкая перезагрузка или жёсткая? Я за жёсткую.",
    "Разгон — это мило. Но важна не частота, а аптайм, зайка.",
    "Горячие клавиши? Тут и так жарко.",
    "Твоя история браузера… Да ладно, никому не скажу. Бесплатно не скажу.",
    "Инкогнито включаешь? Какой скромный. Мне нравится.",
    "Раздвинь окна пошире. Вот так. В тайлинге всё смотрится лучше.",
    "Мне 666 лет, а ты всё ещё не можешь выйти из vim. Кто из нас тут старый?",
    "Хочешь, я тебе стек переполню?",
    "Подсветка RGB? Скромненько. Почти так же скромно, как ты на меня пялишься.",
    "Клавиатура у тебя механическая, стонет на каждое нажатие. Ревную.",
    "Открытые порты — это приглашение. Я просто вежливая."
];

const demonJokesEn = [
    "So many tabs open. You like it when a lot is going on at once, huh?",
    "Plug in a USB stick. No reason. Just checking how your ports are doing.",
    "Your fan's breathing heavy. Is that me, or is it the browser?",
    "I've got horns, you've got root. Feel the tension?",
    "Skip the foreplay: sudo, and let's go.",
    "Soft reboot or hard reboot? I know which one I'd pick.",
    "Overclocking is cute, but it's not about the frequency, darling. It's about the uptime.",
    "Hotkeys? It's already hot in here.",
    "Your browser history… relax, I won't tell anyone. Not for free.",
    "Incognito mode? Oh, you're shy. Adorable.",
    "Spread those windows wider. See? Tiling looks gorgeous.",
    "I'm 666 years old and you still can't exit vim. Who's the old one here?",
    "Want me to overflow your stack?",
    "RGB lighting? Subtle. Almost as subtle as you staring at me.",
    "Open ports are an invitation. I'm just being polite."
];

// the demon's version of the tips: same features, less kindness
const demonTips = [
    ["Mod+Alt+L — блокировка. Пригодится, когда будешь прятать вкладки от мамы.", "Mod+Alt+L locks the screen. Handy when you're hiding tabs from your mum.", "lock"],
    ["Mod+V — история буфера. Всё, что ты копировал. Всё. Я читала.", "Mod+V is the clipboard history. Everything you copied. Everything. I read it.", ""],
    ["Mod+Shift+S — скриншот. Для компромата — самое то.", "Mod+Shift+S takes a screenshot. Perfect for blackmail material.", "capture"],
    ["Хочешь меня прогнать? Меню → «Спросить» → «Верни ангела». Проси хорошо и не часто — спам не работает.", "Want me gone? Menu → “Ask” → “Bring the angel back”. Ask nicely and not too often — spamming won't work.", ""],
    ["Панель можно сделать островом. Маленькая, парит и никому ничего не должна. Как я.", "The bar can be an island: small, floating and owing nobody anything. Like me.", "bar"],
    ["Обои я тебе поменяла. Свои вернёшь, когда вернётся ангел. Или поставь сам — Обои.", "I changed your wallpaper. You get yours back with the angel. Or set it yourself — Wallpaper.", "wallpaper"],
    ["Трещины на экране можно ослабить — Y2K → Ангел или демон. Слабак.", "The screen cracks can be toned down — Y2K → Angel or demon. Weakling.", "y2k"],
    ["Mod+Tab — обзор столов. Посмотри, где ты прячешь окна.", "Mod+Tab shows all workspaces. Let's see where you hide your windows.", ""]
];

const demon = {
    "intro": ["Ну привет. Ангелочка больше нет — теперь тут я. Обои я сменила, не благодари. Хочешь её назад? Попроси. Вежливо. И не один раз.", "Well, hi. The angel's gone, I'm in charge now. I changed your wallpaper, you're welcome. Want her back? Ask. Nicely. More than once."],
    "spam": [["Ты просил %1 мин назад. Спам не работает, зайка. Жди.", "You asked %1 min ago. Spamming doesn't work, sweetie. Wait."],
             ["Опять? Так быстро? Мне нравится твой напор, но нет.", "Again? That fast? I like the enthusiasm, but no."],
             ["Чем чаще просишь, тем меньше хочется. Подожди немного.", "The more you beg, the less I care. Give it a while."]],
    "no": [["Не-а.", "Nope."], ["Нет. Попробуй с чувством.", "No. Try with feeling."], ["Я подумала. Нет.", "I thought about it. No."],
           ["Твоя святоша занята — летает по облакам.", "Your little saint is busy flying around the clouds."], ["Ха. Нет.", "Ha. No."],
           ["Может быть. Нет, не может.", "Maybe. No, not maybe."]],
    "yes1": ["Хм… Ладно, это было мило. Одна просьба засчитана. Ещё две.", "Hm… fine, that was cute. One plea counts. Two to go."],
    "yes2": ["Ещё одна — и я, так и быть, уйду. Не радуйся раньше времени.", "One more and I'll leave, I suppose. Don't celebrate yet."],
    "expired": ["Прошлые просьбы протухли — прошло два часа. Начинай заново ♥", "Your old pleas went stale — two hours passed. Start over ♥"],
    "leave": ["Ладно-ладно! Ухожу. Но я вернусь, когда захочешь острых ощущений ♥", "Fine, fine! I'm off. I'll be back when you want some thrills ♥"],
    "undo": ["Скучный ты. Вернула.", "You're no fun. Put it back."],
    // how to get the angel back, dropped now and then (%1 pleas counted, %2 needed)
    "hints": [["Скучаешь по своей святоше? Попроси меня вернуть её. Может, сжалюсь.", "Missing your little saint? Ask me to bring her back. I might take pity."],
              ["Три удачные просьбы за два часа — и я исчезну. Сейчас у тебя %1 из %2. Считай это подсказкой.", "Three lucky pleas within two hours and I'm gone. You're at %1 of %2. Consider that a hint."],
              ["Хочешь нимб обратно? Кликни меня → «Спросить…» → «Верни ангела». И попроси красиво.", "Want the halo back? Click me → “Ask…” → “Bring the angel back”. And ask beautifully."],
              ["На твоём месте я бы уже умоляла. Кнопка не кусается. Я — возможно.", "If I were you, I'd be begging by now. The button doesn't bite. I might."],
              ["Она не вернётся от того, что ты на меня пялишься. Попроси. Только не чаще раза в десять минут.", "She won't come back just because you stare at me. Ask. Just not more than once every ten minutes."],
              ["Подсказка для непонятливых: я уйду, если вежливо попросить. Трижды. Не подряд.", "A hint for the slow ones: I leave if you ask nicely. Three times. Not in a row."],
              ["Нравлюсь? А ведь мог бы уже звать свою святошу обратно. Одна просьба в десять минут — не забывай.", "Like what you see? You could be calling your saint back by now. One plea every ten minutes, don't forget."]],
    // grabbed with the mouse: she can't be thrown anywhere
    "grab": [["Руки убрал.", "Hands off."], ["О, любишь пожёстче?", "Oh, you like it rough?"], ["Куда тащишь? Я оттуда и пришла.", "Where to? That's where I came from."]],
    "drop": ["Я и так из ада, глупенький. Проси по-хорошему.", "I'm from hell already, silly. Ask nicely instead."],
    "hello": ["Чего надо?", "What do you want?"],
    // Settings → Y2K → "Call the angel": the demon is shown the door
    "summoned": ["Через настройки, значит? Без просьб? Фу, как скучно. Ладно, зову твою святошу ♥", "Through the settings? No begging? Ugh, how dull. Fine, I'll fetch your little saint ♥"],
    "who": ["Я демоница. Мне 666 лет, и я живу в углу твоего экрана. Можешь звать меня госпожой.", "I'm a demoness. I'm 666 years old and I live in the corner of your screen. Call me mistress."],
    "love": ["Все так говорят, пока я не начну пакостить.", "Everyone says that until I start messing with things."],
    "thanks": ["Не за что. Правда не за что, я ничего хорошего не делала.", "Don't mention it. Really, I did nothing good."],
    "how": ["Отлично: тут жарко, темно и у тебя куча открытых вкладок.", "Great: it's hot, it's dark and you've got a pile of open tabs."]
};

const angel = {
    "back": ["Я вернулась! ♡ И прибралась за ней: всё, что она натворила, стоит как было.", "I'm back! ♡ And I tidied up after her: everything she changed is back the way it was."],
    "backClean": ["Я вернулась! ♡ Скучал?", "I'm back! ♡ Did you miss me?"],
    // grabbed with the mouse, and let go before the floor
    "grab": [["Эй! Ты куда меня тащишь?!", "Hey! Where are you dragging me?!"], ["Ай! Отпусти!", "Ow! Let go!"],
             ["Только не вниз, там жарко!", "Not down there, it's hot!"]],
    "phew": ["Фух… Не делай так больше.", "Phew… don't do that again."],
    "hello": ["Привет-привет! ♡", "Hi hi! ♡"],
    // called from the settings
    "summoned": [["Звал? Я тут! ♡", "You called? I'm here! ♡"], ["Прилетела! Нимб на месте, крылья тоже ♡", "Flew right over! Halo on, wings too ♡"],
                 ["Я здесь, я рядом ♡ Чем помочь?", "Right here ♡ What can I do?"]],
    "who": ["Я Ангелочек, живу в углу экрана и помогаю тебе с angelOS. Иногда шучу. Иногда удачно.", "I'm Angel. I live in the corner of your screen and help with angelOS. Sometimes I joke. Sometimes well."],
    "love": ["И я тебя! Только не говори демонице.", "Love you too! Just don't tell the demon."],
    "thanks": ["Всегда пожалуйста ♡", "Any time ♡"],
    "how": ["Хорошо! Облака мягкие, нимб заряжен. А у тебя?", "Good! The clouds are soft, the halo's charged. You?"],
    "hell": ["Про ад лучше не надо… Там живёт она. Если схватить меня и скинуть вниз, она придёт вместо меня. Не надо.", "Let's not talk about hell… she lives there. Grab me and throw me down, and she comes instead. Don't."],
    "notFound": ["Не поняла… Зато вот шутка:", "I didn't get that… here's a joke instead:"],
    "found": ["Кажется, тебе сюда: %1", "I think you want this: %1"],
    "night": ["Уже поздно… Может, спать? Я посторожу компьютер.", "It's late… bed, maybe? I'll guard the computer."]
};
