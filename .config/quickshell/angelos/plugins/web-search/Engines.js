.pragma library

const engines = {
    google: { label: "Google", domain: "www.google.com", url: "https://www.google.com/search?q=%s" },
    duckduckgo: { label: "DuckDuckGo", domain: "duckduckgo.com", url: "https://duckduckgo.com/?q=%s" },
    yandex: { label: "Яндекс", domain: "ya.ru", url: "https://ya.ru/search/?text=%s" },
    ecosia: { label: "Ecosia", domain: "www.ecosia.org", url: "https://www.ecosia.org/search?q=%s" },
    bing: { label: "Bing", domain: "www.bing.com", url: "https://www.bing.com/search?q=%s" },
    brave: { label: "Brave", domain: "search.brave.com", url: "https://search.brave.com/search?q=%s" },
    mojeek: { label: "Mojeek", domain: "www.mojeek.com", url: "https://www.mojeek.com/search?q=%s" }
};

const defaultLinks = [
    "GitHub|https://github.com",
    "GitLab|https://gitlab.com",
    "Codeberg|https://codeberg.org",
    "Reddit|https://reddit.com",
    "YouTube|https://youtube.com",
    "Gmail|https://mail.google.com"
];

function domainOf(url) {
    const m = String(url).match(/^https?:\/\/([^\/]+)/);
    return m ? m[1].replace(/^.*@/, "") : "";
}
