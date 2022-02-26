$(if ($PSCulture -eq 'tr-TR') { ConvertFrom-StringData -StringData @'
    Changes found                                        = Değişiklikler var
    Checking network connectivity...                     = Ag baglantisi denetleniyor...
    Clone target directory already exists: {0}           = Klonlama hedef dizini zaten mevcut: {0}
    Cloning repository failed: {0}                       = Depo getirilemedi: {0}
    Cloning repository: {0}                              = Depo getiriliyor: {0}
    Command failed: ${0}                                 = Komut başarısız: {0}
    Command required: {0}                                = Program gerekiyor: {0}
    DONE                                                 = TAMAM
    Directory not found: {0}                             = Dizin bulunamadı: {0}
    Execution Policy violation                           = Yurutme ilkeleriyle uyumsuzluk
    Failed to determine privileges: {0}                  = Yönetici ayrıcalıkları belirlenemedi: {0}
    File not found: {0}                                  = Dosya bulunamadı: {0}
    Getting from remote failed: {0}                      = URL erişiminde hata: {0}
    Installing {0}                                       = {0} kuruluyor
    Invocation from remote failed: {0}                   = Uzaktan çalıştırma başarısız: {0}
    Malformed URL: {0}                                   = Geçersiz URL: {0}
    No changes found                                     = Değişiklik yok
    No repository found for self                         = Programa ait bir depo belirlenemedi
    Not a file: {0}                                      = Dosya değil: {0}
    Not implemented yet                                  = Henüz gerçeklenmedi
    Not inside a valid repository: {0}                   = Geçerli bir depo içinde değil: {0}
    Operation failed                                     = İşlem başarısız
    Package installation failed: {0}                     = Paketin kurulumu başarısız: {0}
    Package uninstallation failed: {0}                   = Paketin kaldırılması başarısız: {0}
    Package update failed: {0}                           = Paket güncellemesi başarısız: {0}
    Please run this program in an administrator terminal = Lutfen bu programi bir yonetici terminalinde calistirin
    Retrying failed operation: {0}                       = Başarısız işlem tekrar deneniyor: {0}
    Route {0} not found at path {1}                      = {0} rotası {1} dosya yolunda bulunamadı
    Self updating failed                                 = Öz yenileme başarısız
    Skip cloning as the repository seems local: {0}      = Depo yerelde bulunduğundan klonlama yapılmıyor: {0}
    Skip syncing due to the sync type: {0}               = İşlem tipinden dolayı eşzamanlama yapılmıyor: {0}
    URL not found: {0}                                   = URL bulunamadı: {0}
    Uninstalling package: {0}                            = {0} paketi kaldırılıyor
    Updating repository failed                           = Depo yenilemesi başarısız
    Updating repository {0}                              = Depo yenileniyor {0}
    Updating {0}                                         = {0} güncelleniyor

    64 BIT WINDOWS 10 SYSTEM REQUIRED.       = 64 BITLIK BIR WINDOWS 10 ISLETIM SISTEMI GEREKIYOR.
    NETWORK CONNECTION REQUIRED              = AG BAGLANTISI GEREKIYOR
    WINDOWS 10 BUILD {0} OR HIGHER REQUIRED. = WINDOWS 10 BUILD {0} VEYA DAHA YENI BIR SURUM GEREKIYOR.
    WINDOWS 10 OR, A NEWER SYSTEM REQUIRED.  = WINDOWS 10 VEYA DAHA YENI BIR SURUM GEREKIYOR.

    FOR A BETTER WSL EXPERIENCE, UPGRADING TO A MORE LATEST VERSION OF WINDOWS IS RECOMMENDED. = WSL YENILIKLERI ICIN DAHA GUNCEL BIR WINDOWS SURUMUNE YUKSELTME YAPMANIZ ONERILIR.
    YOU DO NOT HAVE SUFFICIENT PERMISSIONS. PLEASE RUN THE FOLLOWING COMMAND AND RETRY:        = YETERLI IZINLERE SAHIP DEGILSINIZ.  LUTFEN SU KOMUTU CALISTIRARAK TEKRAR EDIN:
    YOUR SYSTEM MEETS THE MINIMUM REQUIREMENTS FOR WSL AND, THE INSTALLATION WILL CONTINUE.    = SISTEMINIZ WSL ICIN GEREKLI ASGARI SARTLARI SAGLIYOR VE KURULUM DEVAM EDECEK.
'@}) | importTranslations
