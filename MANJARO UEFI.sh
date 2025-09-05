################################################################
# #### Макет блочной установки Manjaro Linux (BTRFS + SNAPPER) ######
# ################################################################
#
# 🔹 Назначение: Быстрая, гибкая и понятная установка Manjaro Linux
# 🔹 Метод: Копируйте и вставляйте по одному блоку за раз
# 🔹 Важно: Не запускайте как скрипт! Выполняйте вручную.
#
# Структура:
#   1. Подготовка (SSH, Live-среда)
#   2. Диагностика и разметка диска
#   3. Монтирование и установка базовой системы
#   4. Конфигурация внутри chroot
#   5. Установка DE и пост-установочные действия
#
# Примечание:Данная установка предназначена для компьютеров
# с прошивкой Uefi





##########################################################
# ## ⚙️ БЛОК 1: ПОДГОТОВКА LIVE-СРЕДЫ ####################
# ########################################################
#
# Зачем: Подготовка системы: часы, клавиатура, зеркала, обновление.
# Важно: Выполняется в Live-среде (до chroot).
# Включает: Русская раскладка, обновление зеркал, haveged.





clear
pacman-mirrors --country all --api --protocols https --set-branch stable
pacman -Syy
timedatectl set-ntp true
sudo pacman -S --noconfirm pacman-contrib curl
pacman -S --noconfirm haveged manjaro-keyring mlocate inxi util-linux lshw
systemctl enable haveged.service --now
clear
echo ""
echo "##############################################"
echo "## <<< ПОДГОТОВКА К УСТАНОВКЕ ЗАВЕРШЕНА >>> ##"
echo "##############################################"
echo ""






# ######################################################
# ## 🔍 БЛОК 2: ДИАГНОСТИКА ОБОРУДОВАНИЯ ###############
# ######################################################
#
# Зачем: Проверка железа перед установкой и настройкой.
# Важно: Сравните с переменными в следующем блоке.
# Показывает: Процессор, материнка, диски, разделы.





clear && { \
echo "Таблица дисков и разделов:"; \
echo; \
for DEVICE in $(lsblk -dno NAME 2>/dev/null | grep -v -e '^loop' -e '^sr'); do \
    DEVICE_PATH="/dev/$DEVICE"; \
    [[ ! -b "$DEVICE_PATH" ]] && continue; \
    ROTA=$(lsblk -d -o ROTA --noheadings "$DEVICE_PATH" 2>/dev/null | awk '{print $1}'); \
    if [[ "$ROTA" == "1" ]]; then \
        DISK_TYPE="HDD"; \
        MOUNT_OPTIONS="noatime,space_cache=v2,compress=zstd:2,autodefrag"; \
    else \
        DISK_TYPE="SSD"; \
        MOUNT_OPTIONS="ssd,noatime,space_cache=v2,compress=zstd:2,discard=async"; \
    fi; \
    echo "╔═══════════════════════════════════════════════════════════════════════════════════════════════════╗"; \
    printf "║  Диск: %-60s\n" "/dev/$DEVICE"; \
    echo "╠═══════════════════════════════════════════════════════════════════════════════════════════════════╣"; \
    printf "║  Тип: %-60s\n" "$DISK_TYPE"; \
    printf "║  Параметры: %-60s\n" "$MOUNT_OPTIONS"; \
    echo "╚═══════════════════════════════════════════════════════════════════════════════════════════════════╝"; \
    echo; \
done; \
}
echo ""
lsblk
echo ""
echo "Производитель процессора:"
sudo lshw -C cpu 2>/dev/null | grep 'vendor:' | uniq
echo ""
echo "Материнская плата:"
sudo inxi -M
echo ""
echo "Общая информация о системе:"
sudo inxi -I
echo ""
echo "#################################################"
echo "## <<< ТЕСТИРОВАНИЕ КОМПЬЮТЕРА ЗАКОНЧИЛОСЬ >>> ##"
echo "#################################################"
echo ""






# ########################################################
# ## 🔧 БЛОК 3: НАСТРОЙКА ПЕРЕМЕННЫХ (ОБЯЗАТЕЛЬНО!) ######
# ########################################################
#
# Зачем: Настройка под ваше оборудование.
# Важно: Измените значения, если они не совпадают с тестом выше.
# Особое внимание ко всем переменным





##############################################################################
##                    ВАЖНО: Настройка Переменных                           ##
##############################################################################
## Этот раздел ОБЯЗАТЕЛЕН для изменения переменных перед установкой.        ##
## Несоблюдение этого требования может привести к ошибкам установки.        ##
##                                                                          ##
## ПЕРЕД НАЧАЛОМ:                                                           ##
## 1.  Сравните параметры из раздела "Тестирование" с параметрами в         ##
##     таблице переменных ниже.                                             ##
## 2.  Если они НЕ совпадают, ОБЯЗАТЕЛЬНО используйте функцию группового    ##
##     переименования вашего текстового редактора, чтобы переменные в       ##
##     таблице соответствовали результатам тестирования.                    ##
##                                                                          ##
## ДОПОЛНИТЕЛЬНО (по желанию):                                              ##
## Вы можете изменить параметры пользователя, компьютера и ядра.            ##
##############################################################################
##                    Разметка Диска                                        ##
##############################################################################
## Для разметки дисков используется отдельная переменная `sdx`              ##
## (например, `sda`, `sdb` и т.д.), соответствующая выбранному диску.       ##
##                                                                          ##
## ЗАЧЕМ ЭТО НУЖНО:                                                         ##
## Это позволяет избежать конфликтов параметров переменных до и после       ##
## разметки (создания разделов и их монтирования).                          ##
##                                                                          ##
## ПОРЯДОК ДЕЙСТВИЙ:                                                        ##
## 1.  СНАЧАЛА измените переменную `sdx` на нужный диск (например, `sda`).  ##
## 2.  ЗАТЕМ выполните разметку диска.                                      ##
## 3.  ПОСЛЕ разметки диска изменяйте переменные разделов                   ##
##     (например, `sda1`, `sda2`, `sda3`).                                  ##
##                                                                          ##
## ТЕСТИРОВАНИЕ:                                                            ##
## Вы можете использовать тестирование из блока 3 ДО заполнения всех        ##
## переменных.                                                              ##
## ПОСЛЕ заполнения всех переменных вы можете С УВЕРЕННОСТЬЮ приступить     ##
## к установке Manjaro Linux!                                               ##
##############################################################################

#############################################################
#                      Настройки языка                      #
#                     Language settings                     #
#############################################################
#                       Переменная                          #
#                        Variable                           #
#############################################################
#         #  locale.gen   # loadkeys, keymap #  font        #
#############################################################
# Country #  XXXX        #  YYYY            #  ZZZZ         #
#############################################################
# Russia  #  ru_RU       #  ru              #  cyr-sun16    #
# Ukraine #  uk_UA       #  uk              #  UniCyr_8x16  #
# Belarus #  be_BY       #  by              #  cyr-sun16    #
# Germany #  de_DE       #  de              #  lat9w-16     #
# France  #  fr_FR       #  fr              #  lat9w-16     #
# Spain   #  es_ES       #  es              #  lat9w-16     #
# Italy   #  it_IT       #  it              #  lat9w-16     #
# USA     #  en_US       #  en              #  lat9w-16     #
#############################################################

#############################################################
#             Объект             #   Переменная             #
#############################################################
#             Имя                #  forename	                #
#############################################################
#             Полное имя         #  User Name               #
#############################################################
#             HOSTNAME 	         #  Sony                    #
#############################################################
#             Microcode	         #  amd-ucode               #
#############################################################
#               Ядро	         #  linux612                #
#############################################################
#            размер SWAP	     #	4G                      #
#############################################################
#         Диск для разметки      #  sdx                     #
#############################################################
# Разделы диска для монтирования #  sda1 sda2 sda3          #
#############################################################

#############################################################
#           Переменная BTRFS (SSD/HDD) FSTAB                #
#############################################################
#                        defaults                           #
#############################################################






# ################################################
# ## 🗂️ БЛОК 4: РАЗМЕТКА ДИСКА (GPT + EFI) #######
# ################################################
#
# Зачем: Создание разделов: UEFI Boot, root, swap.
# Важно: Все данные будут удалены!
# Используется: sgdisk для точной разметки.





clear
wipefs --all --force /dev/sdx
sgdisk -Z /dev/sdx
sgdisk -a 2048 -o /dev/sdx
sgdisk -n 1::+1024M --typecode=1:ef00 --change-name=1:'Раздел Efi Manjaro Linux' /dev/sdx
sgdisk -n 2::-4G --typecode=2:8300 --change-name=2:'Системный раздел Manjaro Linux' /dev/sdx
sgdisk -n 3::-0 --typecode=3:8200 --change-name=3:'Раздел подкачки Manjaro Linux' /dev/sdx
clear
echo ""
gdisk -l /dev/sdx
fdisk -l /dev/sdx
echo ""
echo ""
echo "######################################"
echo "## <<< РАЗМЕТКА ДИСКА ЗАВЕРШЕНА >>> ##"
echo "######################################"
echo ""






# #######################################################
# ## 💾 БЛОК 5: ФОРМАТИРОВАНИЕ И МОНТИРОВАНИЕ ###########
# #######################################################
#
# Зачем: Форматирование, создание подтомов Btrfs, монтирование.
# Важно: Выполняется до chroot.
# Подтомы: @, @home, @log, @pkg.





clear
mkfs.fat -F32 /dev/sda1
mkswap /dev/sda3
swapon /dev/sda3
mkfs.btrfs -f /dev/sda2
mount /dev/sda2 /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
btrfs su cr /mnt/@log
btrfs su cr /mnt/@pkg
umount /mnt
mount -o defaults,subvol=@ /dev/sda2 /mnt
mkdir -p /mnt/{boot,home,var/log,var/cache/pacman/pkg,var/lib/machines,var/lib/portables}
mount -o defaults,subvol=@home /dev/sda2 /mnt/home
mount -o defaults,subvol=@log /dev/sda2 /mnt/var/log
mount -o defaults,subvol=@pkg /dev/sda2 /mnt/var/cache/pacman/pkg
mount /dev/sda1 /mnt/boot
clear
echo ""
# Просмотр информации о разделах (проверка)
lsblk -o PATH,PTTYPE,PARTTYPE,FSTYPE,PARTTYPENAME /dev/sdx
echo ""
# Просмотр созданных подтомов (после монтирования)
lsblk /dev/sdx
echo ""
# Просмотр созданных подтомов (после монтирования)
btrfs subvolume list /mnt
echo ""
echo "##############################################################"
echo "## <<< ФОРМАТИРОВАНИЕ И МОНТИРОВАНИЕ РАЗДЕЛОВ ЗАВЕРШЕНО >>> ##"
echo "##############################################################"
echo ""






# ########################################################
# ## 🧱 БЛОК 6: УСТАНОВКА БАЗОВЫХ ПАКЕТОВ ###############
# ########################################################
#
# Зачем: Установка минимальной системы и переход в chroot.
# Важно: После этого — вход в chroot.
# Включает: base, pacman-contrib, curl.





clear
basestrap /mnt base
basestrap /mnt manjaro-keyring
basestrap /mnt pacman-contrib curl
fstabgen -pU /mnt >> /mnt/etc/fstab
clear
echo ""
echo "##################################################"
echo "## <<< УСТАНОВКА БАЗОВЫХ ПАКЕТОВ ЗАВЕРШЕНА >>> ##"
echo "## <<< СОВЕРШАЕМ ВХОД В СИСТЕМУ (chroot)    >>> ##"
echo "##################################################"
echo ""
manjaro-chroot /mnt /bin/bash
echo ""






# ########################################################
# ## 🔁 БЛОК 7: НАСТРОЙКА ВНУТРИ СИСТЕМЫ (chroot) #######
# ########################################################
#
# Зачем: Настройка системы: локали, fstab, время, зеркала.
# Важно: Выполняется внутри chroot.
# Автоматизация: Временная зона по IP, зеркала по стране.






clear
sed -i 's/\S*subvol=\(\S*\)/subvol=\1,noatime,space_cache=v2,compress=zstd:2,autodefrag/g'  /etc/fstab
sed -i s/'#ParallelDownloads'/'ParallelDownloads'/g /etc/pacman.conf
sed -i s/'ParallelDownloads = 4'/'ParallelDownloads = 15'/g /etc/pacman.conf
sed -i s/'#Color'/'Color'/g /etc/pacman.conf
sed -i 's/#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
sed -i 's/#DisableSandbox/DisableSandbox/' /etc/pacman.conf
sed -i 's/#ILoveCandy/ILoveCandy/' /etc/pacman.conf
echo "KEYMAP=ru" > /etc/vconsole.conf
echo "FONT=cyr-sun16" >> /etc/vconsole.conf
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
sed -i "s/#ru_RU/ru_RU/" /etc/locale.gen
sed -i "s/#en_US/en_US/" /etc/locale.gen
locale-gen
export LANG=ru_RU.UTF-8
time_zone=$(curl -s https://ipinfo.io/timezone    )
ln -sf /usr/share/zoneinfo/$time_zone /etc/localtime
hwclock --systohc
pacman-mirrors --country all --api --protocols https --set-branch stable
pacman -Syy
clear
echo ""
date
echo ""
echo "############################################"
echo "## <<< ПЕРВОНАЧАЛЬНАЯ НАСТРОЙКА ЗАВЕРШЕНА ##"
echo "############################################"
echo ""






# ######################################################
# ## 🌌 БЛОК 8: УСТАНОВКА ГРАФИЧЕСКОЙ СРЕДЫ ###########
# ######################################################
#
# Зачем: Выбор удобной среды .
# Включает: Все компоненты системы





# #######################################################
# ## 🌌 УСТАНОВКА KDE PLASMA ###########################
# #######################################################
#
# Зачем: Установка среды KDE Plasma.
# Включает: Все компоненты, SDDM, kde-applications.






clear
#### KDE PLASMA ####
pacman -Syy
# === ЯДРО СИСТЕМЫ И БАЗОВЫЕ КОМПОНЕНТЫ ===
pacman -S --noconfirm linux612 linux-firmware-meta amd-ucode memtest86+-efi mkinitcpio-openswap
# === ЗАГРУЗЧИК И ЭКРАН ЗАГРУЗКИ ===
pacman -S --noconfirm grub grub-btrfs grub-theme-manjaro install-grub update-grub os-prober efibootmgr plymouth plymouth-kcm plymouth-theme-manjaro
# === СИСТЕМНЫЕ БИБЛИОТЕКИ И УТИЛИТЫ ===
pacman -S --noconfirm glibc-locales man-db man-pages sudo less vi nano micro nano-syntax-highlighting which diffutils rsync wget texinfo logrotate sysfsutils perl python-pillow python-pip python-pyqt5 python-pysmbc python-reportlab s-nail dmidecode xdg-user-dirs xdg-utils usbutils
# === УПРАВЛЕНИЕ ХРАНЕНИЕМ ДАННЫХ ===
pacman -S --noconfirm btrfs-progs dosfstools e2fsprogs exfatprogs f2fs-tools jfsutils xfsprogs ntfs-3g cryptsetup device-mapper lvm2 mdadm dmraid udisks2 udiskie
# === СЕТЕВЫЕ ВОЗМОЖНОСТИ ===
pacman -S --noconfirm networkmanager networkmanager-l2tp networkmanager-openconnect networkmanager-openvpn networkmanager-vpnc dnsmasq inetutils openssh nfs-utils nss-mdns wpa_supplicant wireless-regdb modemmanager
# === ЗВУКОВАЯ СИСТЕМА И МЕДИА ===
pacman -S --noconfirm alsa-firmware alsa-utils manjaro-alsa manjaro-pipewire sof-firmware
# === ЯДРО ГРАФИЧЕСКОЙ ОБОЛОЧКИ KDE PLASMA ===
pacman -S --noconfirm plasma-desktop plasma-workspace plasma-workspace-wallpapers kdeplasma-addons kwin kscreen kscreenlocker kwrited kwayland-integration breeze5 breeze-gtk kde-gtk-config sddm sddm-breath-theme sddm-kcm
# === ОСНОВНЫЕ ПРИЛОЖЕНИЯ KDE ===
pacman -S --noconfirm dolphin dolphin-plugins konsole kate kcalc gwenview okular ark spectacle skanlite kamera filelight kfind keditbookmarks milou yakuake
# === СИСТЕМНЫЕ НАСТРОЙКИ И УТИЛИТЫ KDE ===
pacman -S --noconfirm systemsettings kinfocenter khelpcenter kscreenlocker kgamma kwallet-pam kwalletmanager ksshaskpass ksystemlog print-manager
# === ИНТЕГРАЦИЯ И АППЛЕТЫ KDE ===
pacman -S --noconfirm plasma-nm plasma-pa plasma-systemmonitor plasma-thunderbolt plasma-browser-integration powerdevil bluedevil kdeconnect xdg-desktop-portal-kde kaccounts-providers
# === КОНФИГУРАЦИЯ И НАСТРОЙКА KDE ===
pacman -S --noconfirm kdenetwork-filesharing kdegraphics-thumbnailers kmenuedit
# === ДОПОЛНИТЕЛЬНЫЕ МОДУЛИ И ПОДДЕРЖКА ФОРМАТОВ KDE ===
pacman -S --noconfirm kio-extras kimageformats audiocd-kio
# === ШРИФТЫ ===
pacman -S --noconfirm adobe-source-sans-fonts noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-dejavu ttf-droid ttf-inconsolata ttf-indic-otf ttf-liberation terminus-font
# === ТЕМЫ И ЗНАЧКИ ===
pacman -S --noconfirm papirus-icon-theme gnome-themes-extra
# === ГРАФИЧЕСКИЕ БИБЛИОТЕКИ GTK/QT ===
pacman -S --noconfirm gtk3 gtkmm3 lib32-mesa lib32-mesa-utils mesa-utils libva-intel-driver lib32-libva-intel-driver qt6-imageformats qt6-virtualkeyboard lib32-libcanberra libcanberra
# === НАСТРОЙКИ И УТИЛИТЫ MANJARO ===
pacman -S --noconfirm manjaro-hello manjaro-kde-settings manjaro-application-utility manjaro-browser-settings manjaro-gstreamer manjaro-release manjaro-settings-manager-knotifier manjaro-system manjaro-zsh-config manjaro-modem manjaro-printer
# === ОБСЛУЖИВАНИЕ И БЕЗОПАСНОСТЬ СИСТЕМЫ ===
pacman -S --noconfirm mhwd mhwd-db acpi acpid b43-fwcutter fwupd sbctl open-vm-tools virtualbox-guest-utils qemu-guest-agent spice-vdagent udev-usb-sync
# === ДОПОЛНИТЕЛЬНЫЕ УТИЛИТЫ И ПОДДЕРЖКА ПЕРИФЕРИИ ===
pacman -S --noconfirm mtpfs perl-file-mimeinfo poppler-data ntp numlockx power-profiles-daemon ecryptfs-utils cronie usb_modeswitch
# === СЕРВЕР X WINDOW SYSTEM И ДРАЙВЕРА ВВОДА ===
pacman -S --noconfirm xorg-server xorg-xinit xorg-twm xorg-xkill xorg-mkfontscale xf86-input-elographics xf86-input-evdev xf86-input-libinput xf86-input-vmmouse xf86-input-void
# === АРХИВАТОРЫ И УТИЛИТЫ ДЛЯ РАБОТЫ С АРХИВАМИ ===
pacman -S --noconfirm unarchiver 7zip
# === ПЛАГИНЫ И РАСШИРЕНИЯ ДЛЯ DOLPHIN ===
pacman -S --noconfirm dolphin-plugins
# === МОНИТОРИНГ И ИНФОРМАЦИЯ О СИСТЕМЕ ===
pacman -S --noconfirm htop powertop cpupower inxi fastfetch
# === ВЕБ-БРАУЗЕРЫ ===
pacman -S --noconfirm firefox
# === ВИДЕОПРОГРАВЫВАТЕЛИ ===
pacman -S --noconfirm vlc
# === АУДИОПРОГРАВЫВАТЕЛИ ===
pacman -S --noconfirm elisa
# === СИСТЕМЫ РЕЗЕРВНОГО КОПИРОВАНИЯ ===
pacman -S --noconfirm timeshift timeshift-autosnap-manjaro
# === МЕНЕДЖЕР ПАКЕТОВ PAMAC ===
pacman -S --noconfirm pamac-tray-icon-plasma
# === АКТИВАЦИЯ СИСТЕМНЫХ СЕРВИСОВ ===
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups
systemctl enable avahi-daemon
systemctl enable cronie
systemctl enable ModemManager
systemctl enable sshd
systemctl enable sddm
systemctl enable power-profiles-daemon
systemctl enable udisks2
systemctl enable accounts-daemon
systemctl enable acpid
clear
echo ""
echo "#############################################"
echo "## <<<  УСТАНОВКА KDE PLASMA ЗАВЕРШЕНА >>> ##"
echo "#############################################"
echo ""





# #######################################################
# ## 🌐 УСТАНОВКА GNOME #################################
# #######################################################
#
# Зачем: Установка GNOME с полной интеграцией.
# Включает: GDM, portal, apps, extensions.





clear
#### GNOME ####
pacman -Syy
# === ЯДРО СИСТЕМЫ И БАЗОВЫЕ КОМПОНЕНТЫ ===
pacman -S --noconfirm linux612 linux-firmware-meta amd-ucode memtest86+-efi mkinitcpio-openswap
# === ЗАГРУЗЧИК И ЭКРАН ЗАГРУЗКИ ===
pacman -S --noconfirm grub grub-btrfs grub-theme-manjaro install-grub update-grub os-prober efibootmgr plymouth-theme-manjaro
# === СИСТЕМНЫЕ БИБЛИОТЕКИ И УТИЛИТЫ ===
pacman -S --noconfirm glibc-locales man-db man-pages man-pages posix-util-linux sudo less vi nano micro nano-syntax-highlighting which diffutils rsync wget texinfo logrotate sysfsutils perl python3 s-nail dmidecode xdg-user-dirs xdg-utils usbutils
# === УПРАВЛЕНИЕ ХРАНЕНИЕМ ДАННЫХ ===
pacman -S --noconfirm btrfs-progs dosfstools e2fsprogs exfatprogs f2fs-tools jfsutils xfsprogs ntfs-3g cryptsetup device-mapper lvm2 mdadm dmraid btrfsmaintenance
# === СЕТЕВЫЕ ВОЗМОЖНОСТИ ===
pacman -S --noconfirm networkmanager networkmanager-openconnect networkmanager-openvpn network-manager-sstp networkmanager-strongswan networkmanager-vpnc dnsmasq inetutils openssh nfs-utils nss-mdns wpa_supplicant wireless-regdb modemmanager
# === ЗВУКОВАЯ СИСТЕМА И МЕДИА ===
pacman -S --noconfirm manjaro-alsa manjaro-pipewire sof-firmware ffmpegthumbnailer ffmpeg-audio-thumbnailer
# === ЯДРО ГРАФИЧЕСКОЙ ОБОЛОЧКИ GNOME ===
pacman -S --noconfirm gnome-shell gnome-control-center gnome-settings-daemon mutter gdm
# === ОСНОВНЫЕ ПРИЛОЖЕНИЯ GNOME ===
pacman -S --noconfirm nautilus gnome-console gnome-text-editor gnome-calendar gnome-clocks gnome-contacts gnome-maps gnome-weather gnome-calculator gnome-characters gnome-font-viewer gnome-system-monitor gnome-logs gnome-tweaks gnome-user-docs gnome-disk-utility gnome-firmware
# === БАЗОВЫЕ ТЕМЫ И ЗНАЧКИ GNOME ===
pacman -S --noconfirm gnome-themes-extra gnome-backgrounds
# === СЕТЕВЫЕ И МУЛЬТИМЕДИЙНЫЕ СЕРВИСЫ GNOME ===
pacman -S --noconfirm gnome-browser-connector gnome-user-share gnome-remote-desktop grilo-plugins rygel
# === ОСНОВНЫЕ РАСШИРЕНИЯ GNOME SHELL ===
pacman -S --noconfirm gnome-shell-extensions gnome-shell-extension-appindicator gnome-shell-extension-gsconnect
# === НАСТРОЙКИ И УТИЛИТЫ MANJARO (GNOME-специфичные) ===
pacman -S --noconfirm manjaro-hello manjaro-gnome-settings manjaro-gnome-extension-settings manjaro-gnome-backgrounds manjaro-application-utility manjaro-browser-settings manjaro-gstreamer
# === ОБСЛУЖИВАНИЕ И БЕЗОПАСНОСТЬ СИСТЕМЫ ===
pacman -S --noconfirm mhwd mhwd-db apparmor sbctl open-vm-tools virtualbox-guest-utils qemu-guest-agent spice-vdagent b43-fwcutter
# === ИНТЕГРАЦИЯ С ПЕРИФЕРИЕЙ И ДОПОЛНИТЕЛЬНЫЕ СИСТЕМНЫЕ СЕРВИСЫ ===
pacman -S --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd udev-usb-sync cpupower power-profiles-daemon ecryptfs-utils cronie gtksourceview-pkgbuild
# === ДОПОЛНИТЕЛЬНЫЕ РАСШИРЕНИЯ GNOME SHELL ===
pacman -S --noconfirm gnome-shell-extension-arc-menu gnome-shell-extension-dash-to-dock gnome-shell-extension-dash-to-panel gnome-shell-extension-forge gnome-shell-extension-gnome-ui-tune gnome-shell-extension-gtk4-desktop-icons-ng gnome-shell-extension-legacy-theme-auto-switcher gnome-shell-extension-space-bar
# === ДОПОЛНИТЕЛЬНОЕ ОФОРМЛЕНИЕ GNOME ===
pacman -S --noconfirm adw-gtk-theme kvantum-manjaro papirus-maia-icon-theme
# === СПЕЦИАЛИЗИРОВАННЫЕ GNOME СЕРВИСЫ ===
pacman -S --noconfirm endeavour collision webapp-manager fprintd malcontent
# === ШРИФТЫ ===
pacman -S --noconfirm noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra ttf-dejavu ttf-hack-nerd ttf-indic-otf
# === НАСТРОЙКИ И УТИЛИТЫ MANJARO (общесистемные) ===
pacman -S --noconfirm manjaro-release manjaro-settings-manager manjaro-settings-manager-notifier manjaro-system manjaro-zsh-config manjaro-base-skel manjaro-input manjaro-modem manjaro-printer manjaro-settings-samba
# === ПЛАГИНЫ И РАСШИРЕНИЯ ДЛЯ NAUTILUS ===
pacman -S --noconfirm nautilus-admin nautilus-empty-file nautilus-open-any-terminal
# === АРХИВАТОРЫ И УТИЛИТЫ ДЛЯ РАБОТЫ С АРХИВАМИ ===
pacman -S --noconfirm 7zip unrar unace zip squashfs-tools
# === ИНСТРУМЕНТЫ НАСТРОЙКИ ВНЕШНОСТИ ПРИЛОЖЕНИЙ ===
pacman -S --noconfirm qt5ct qt6ct
# === ДОПОЛНИТЕЛЬНЫЕ УТИЛИТЫ GNOME ===
pacman -S --noconfirm gnome-boxes gnome-connections gnome-chess iagno quadrapassel snapshot simple-scan file-roller baobab seahorse
# === МОНИТОРИНГ И ИНФОРМАЦИЯ О СИСТЕМЕ ===
pacman -S --noconfirm htop inxi
# === ИГРЫ ===
pacman -S --noconfirm gnome-chess iagno quadrapassel
# === ВЕБ-БРАУЗЕРЫ ===
pacman -S --noconfirm firefox
# === ПОЧТОВЫЕ КЛИЕНТЫ ===
pacman -S --noconfirm thunderbird
# === ТОРРЕНТ-КЛИЕНТЫ ===
pacman -S --noconfirm fragments
# === ВИДЕОПРОГРАВЫВАТЕЛИ ===
pacman -S --noconfirm totem
# === АУДИОПРОГРАВЫВАТЕЛИ ===
pacman -S --noconfirm lollypop decibels
# === ПРОСМОТР И РАБОТА С ИЗОБРАЖЕНИЯМИ ===
pacman -S --noconfirm gthumb sushi
# === СИСТЕМЫ РЕЗЕРВНОГО КОПИРОВАНИЯ ===
pacman -S --noconfirm timeshift timeshift-autosnap-manjaro
# === АКТИВАЦИЯ СИСТЕМНЫХ СЕРВИСОВ ===
systemctl enable NetworkManager
systemctl enable bluetooth # (Зависит от установки bluez)
systemctl enable cups # (Зависит от установки cups)
systemctl enable avahi-daemon
systemctl enable cronie
systemctl enable ModemManager
systemctl enable sshd
systemctl enable gdm # Основной дисплейный менеджер для GNOME
systemctl enable power-profiles-daemon
clear
echo ""
echo "########################################"
echo "## <<<  УСТАНОВКА GNOME ЗАВЕРШЕНА >>> ##"
echo "########################################"
echo ""





#######################################################
# ## 🔋 ПИТАНИЕ НОУТБУКА (настройки logind) #############
# #######################################################
#
# Зачем: Управление действиями при нажатии кнопки питания,
#        закрытии крышки, сне и гибернации.
#
# Важно: GNOME частично управляет питанием через "Настройки → Электропитание".
#        Эти настройки systemd (logind) — базовые и применяются, даже если GNOME не запущен.
#        Чтобы избежать конфликтов, рекомендуется:
#        - Настройки сна/крышки — через systemd (здесь)
#        - Яркость, поведение в режиме сна — через GNOME
#

## 🔹 Вариант 1 (рекомендуется для большинства)
## Кнопка питания — выключает компьютер.
## Закрытие крышки — переводит в сон (при питании от батареи или сети).
## В док-станции — игнорируется.
# mkdir -p /etc/systemd/logind.conf.d
# echo "[Login]" > /etc/systemd/logind.conf.d/50-power-options.conf
# echo "HandlePowerKey=poweroff" >> /etc/systemd/logind.conf.d/50-power-options.conf
# echo "HandleLidSwitch=suspend" >> /etc/systemd/logind.conf.d/50-power-options.conf
# echo "HandleLidSwitchDocked=ignore" >> /etc/systemd/logind.conf.d/50-power-options.conf
# ✅ Подходит для большинства пользователей GNOME.

## 🔹 Вариант 2 (для продвинутых, с гибернацией)
## Кнопка питания — выключает.
## Закрытие крышки — гибернация (даже при подключённом питании).
## Требует настроенной гибернации (swap/hibernate-resume).
# mkdir -p /etc/systemd/logind.conf.d
# echo "[Login]" > /etc/systemd/logind.conf.d/50-power-options.conf
# echo "HandlePowerKey=poweroff" >> /etc/systemd/logind.conf.d/50-power-options.conf
# echo "HandleLidSwitch=hibernate" >> /etc/systemd/logind.conf.d/50-power-options.conf
# echo "HandleLidSwitchExternalPower=hibernate" >> /etc/systemd/logind.conf.d/50-power-options.conf
# echo "HandleLidSwitchDocked=hibernate" >> /etc/systemd/logind.conf.d/50-power-options.conf
# ⚠️ Требует: swap-раздел >= RAM, настройка resume в kernel params.

## 🔹 Вариант 3 (максимальная свобода)
## Кнопка питания — выключает.
## Крышка — сон при автономной работе, игнор при подключённом питании и в доке.
# mkdir -p /etc/systemd/logind.conf.d
# echo "[Login]" > /etc/systemd/logind.conf.d/50-power-options.conf
# echo "HandlePowerKey=poweroff" >> /etc/systemd/logind.conf.d/50-power-options.conf
# echo "HandleLidSwitch=suspend" >> /etc/systemd/logind.conf.d/50-power-options.conf
# echo "HandleLidSwitchExternalPower=ignore" >> /etc/systemd/logind.conf.d/50-power-options.conf
# echo "HandleLidSwitchDocked=ignore" >> /etc/systemd/logind.conf.d/50-power-options.conf
# 💡 Полезно, если вы часто подключаете ноутбук к внешнему дисплею.

# ✅ После установки можно изменить поведение в:
#     Настройки GNOME → Электропитание
#     Или вручную отредактировав /etc/systemd/logind.conf.d/50-power-options.conf






# ########################################################
# ## 🪟 УСТАНОВКА XFCE4 ##################################
# ########################################################
#
# Зачем: Установка XFCE4 с расширенными компонентами.
# Включает: LightDM, plugins, apps.




clear
# === ЯДРО СИСТЕМЫ И БАЗОВЫЕ КОМПОНЕНТЫ ===
pacman -S --noconfirm linux612 linux-firmware-meta amd-ucode memtest86+-efi mkinitcpio-openswap bash-completion
# === ЗАГРУЗЧИК И ЭКРАН ЗАГРУЗКИ ===
pacman -S --noconfirm grub grub-btrfs grub-theme-manjaro install-grub update-grub os-prober efibootmgr plymouth plymouth-theme-manjaro
# === СИСТЕМНЫЕ БИБЛИОТЕКИ И УТИЛИТЫ ===
pacman -S --noconfirm glibc-locales man-db man-pages sudo less vi nano micro nano-syntax-highlighting which diffutils rsync wget texinfo logrotate sysfsutils perl s-nail dmidecode xdg-user-dirs xdg-utils usbutils plocate
# === УПРАВЛЕНИЕ ХРАНЕНИЕМ ДАННЫХ ===
pacman -S --noconfirm btrfs-progs dosfstools e2fsprogs exfatprogs f2fs-tools jfsutils xfsprogs ntfs-3g cryptsetup device-mapper lvm2 mdadm dmraid udisks2 udiskie
# === СЕТЕВЫЕ ВОЗМОЖНОСТИ ===
pacman -S --noconfirm networkmanager network-manager-applet networkmanager-openconnect networkmanager-openvpn networkmanager-vpnc dnsmasq inetutils openssh nfs-utils nss-mdns wpa_supplicant wireless-regdb modemmanager
# === ЗВУКОВАЯ СИСТЕМА И МЕДИА ===
pacman -S --noconfirm alsa-firmware alsa-utils manjaro-alsa manjaro-pipewire sof-firmware gst-libav gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly libdvdcss ffmpeg
# === ЯДРО ГРАФИЧЕСКОЙ ОБОЛОЧКИ XFCE4 ===
# КРИТИЧЕСКИ ВАЖНЫЕ пакеты для запуска сессии:
pacman -S --noconfirm xfce4-session xfce4-panel xfdesktop xfwm4 xfconf xfce4-settings thunar garcon
# === ОСНОВНЫЕ ПЛАГИНЫ И КОМПОНЕНТЫ XFCE4 ===
pacman -S --noconfirm xfce4-notifyd xfce4-appfinder xfce4-terminal xfce4-taskmanager xfce4-screensaver xfce4-screenshooter xfce4-whiskermenu-plugin xfce4-power-manager
# === ВИДЖЕТЫ И ПЛАГИНЫ ПАНЕЛИ XFCE4 ===
pacman -S --noconfirm xfce4-battery-plugin xfce4-clipman-plugin xfce4-cpufreq-plugin xfce4-cpugraph-plugin xfce4-dict xfce4-diskperf-plugin xfce4-fsguard-plugin xfce4-genmon-plugin xfce4-mailwatch-plugin xfce4-mount-plugin xfce4-mpc-plugin xfce4-netload-plugin xfce4-notes-plugin xfce4-pulseaudio-plugin xfce4-sensors-plugin xfce4-smartbookmark-plugin xfce4-systemload-plugin xfce4-time-out-plugin xfce4-timer-plugin xfce4-verve-plugin xfce4-wavelan-plugin xfce4-weather-plugin xfce4-xkb-plugin
# === ПЛАГИНЫ ДЛЯ THUNAR ===
pacman -S --noconfirm thunar-archive-plugin thunar-media-tags-plugin thunar-volman tumbler ffmpegthumbnailer libgsf libopenraw exo
# === НАСТРОЙКИ И УТИЛИТЫ MANJARO ===
pacman -S --noconfirm manjaro-hello manjaro-xfce-settings manjaro-application-utility manjaro-browser-settings manjaro-gstreamer manjaro-release manjaro-settings-manager manjaro-settings-manager-notifier manjaro-system manjaro-zsh-config manjaro-modem manjaro-printer manjaro-wallpapers-18.0 wallpapers-2018 wallpapers-juhraya
# === ОБСЛУЖИВАНИЕ И БЕЗОПАСНОСТЬ СИСТЕМЫ ===
pacman -S --noconfirm mhwd mhwd-db acpi acpid b43-fwcutter sbctl open-vm-tools virtualbox-guest-utils qemu-guest-agent spice-vdagent apparmor
# === ИНТЕГРАЦИЯ С ПЕРИФЕРИЕЙ И ДОПОЛНИТЕЛЬНЫЕ СИСТЕМНЫЕ СЕРВИСЫ ===
pacman -S --noconfirm gvfs gvfs-afc gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-smb udev-usb-sync accountsservice gnome-keyring xiccd
# === ДОПОЛНИТЕЛЬНЫЕ УТИЛИТЫ И ПОДДЕРЖКА ПЕРИФЕРИИ ===
pacman -S --noconfirm mtpfs perl-file-mimeinfo poppler-data poppler-glib ntp numlockx cronie usb_modeswitch android-tools android-udev freetype2 ecryptfs-utils samba
# === СЕРВЕР X WINDOW SYSTEM И ДРАЙВЕРА ВВОДА ===
pacman -S --noconfirm xorg-server xorg-xinit xorg-twm xorg-xkill xorg-mkfontscale xf86-input-elographics xf86-input-evdev xf86-input-libinput xf86-input-vmmouse xf86-input-void
# === АРХИВАТОРЫ И УТИЛИТЫ ДЛЯ РАБОТЫ С АРХИВАМИ ===
pacman -S --noconfirm engrampa 7zip unace unrar
# === ШРИФТЫ ===
pacman -S --noconfirm adobe-source-sans-fonts noto-fonts noto-fonts-cjk ttf-dejavu ttf-droid ttf-inconsolata ttf-indic-otf ttf-liberation terminus-font
# === ТЕМЫ И ЗНАЧКИ ===
pacman -S --noconfirm matcha-gtk-theme papirus-icon-theme gnome-themes-extra xcursor-simpleandsoft xcursor-vanilla-dmz-aa
# === ГРАФИЧЕСКИЕ БИБЛИОТЕКИ ===
pacman -S --noconfirm gtkmm3 lib32-mesa lib32-mesa-utils mesa-utils libva-intel-driver lib32-libva-intel-driver
# === ПОРТАЛЫ РАБОЧЕГО СТОЛА ===
pacman -S --noconfirm xdg-desktop-portal-gtk
# === УТИЛИТЫ ДЛЯ РАБОТЫ С ФАЙЛАМИ ===
pacman -S --noconfirm mousepad galculator xfburn mugshot menulibre gcolor3 evince yelp gparted
# === ФАЙЛОВЫЕ МЕНЕДЖЕРЫ ===
pacman -S --noconfirm thunar catfish
# === SNAP ПАКЕТЫ ===
pacman -S --noconfirm snapd snapd-glib
# === МОНИТОРИНГ И ИНФОРМАЦИЯ О СИСТЕМЕ ===
pacman -S --noconfirm htop powertop cpupower inxi screenfetch
# === ВЕБ-БРАУЗЕРЫ ===
pacman -S --noconfirm firefox
# === ПОЧТОВЫЕ КЛИЕНТЫ ===
pacman -S --noconfirm thunderbird
# === БРАНДМАУЭР ===
pacman -S --noconfirm gufw
# === ВИДЕОПРОГРАВЫАТЕЛИ ===
pacman -S --noconfirm vlc
# === АУДИОПРОГРАВЫАТЕЛИ ===
pacman -S --noconfirm audacious
# === МИКШЕРЫ ЗВУКА ===
pacman -S --noconfirm pavucontrol
# === МЕССЕНДЖЕРЫ ===
pacman -S --noconfirm pidgin
# === ГРАФИЧЕСКИЕ РЕДАКТОРЫ ===
pacman -S --noconfirm gimp
# === ПРОСМОТР И РАБОТА С ИЗОБРАЖЕНИЯМИ ===
pacman -S --noconfirm viewnior
# === СИСТЕМЫ РЕЗЕРВНОГО КОПИРОВАНИЯ ===
pacman -S --noconfirm timeshift timeshift-autosnap-manjaro
# === МЕНЕДЖЕР ВХОДА (DISPLAY MANAGER) ===
pacman -S --noconfirm lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings blueman
# === АКТИВАЦИЯ СИСТЕМНЫХ СЕРВИСОВ ===
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups
systemctl enable avahi-daemon
systemctl enable cronie
systemctl enable ModemManager
systemctl enable sshd
systemctl enable lightdm
systemctl enable udisks2
systemctl enable accounts-daemon
systemctl enable acpid
systemctl enable snapd.apparmor
clear
echo ""
echo "########################################"
echo "## <<<  УСТАНОВКА XFCE4 ЗАВЕРШЕНА >>> ##"
echo "########################################"
echo ""






# #######################################################
# ## 🔧 БЛОК 9: НАСТРОЙКА КОНФИГУРАЦИИ GRUB, INITRAMFS ##
# #######################################################
#
# Зачем: Настройка загрузчика и initramfs.
# Включает: GRUB, grub-btrfs, plymouth, resume из swap.





clear
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --modules="btrfs"
SWAP_UUID=$(blkid -s UUID -o value /dev/sda3)
sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash plymouth resume=UUID=${SWAP_UUID} udev.log_priority=3 rootflags=subvol=@\"|" /etc/default/grub
sed -i "s/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/" /etc/default/grub
sed -i "s/#GRUB_BTRFS_SUBMENUNAME=\"Arch Linux snapshots\"/GRUB_BTRFS_SUBMENUNAME=\"Manjaro Linux snapshots\"/" /etc/default/grub-btrfs/config
sed -i "s/#GRUB_BTRFS_TITLE_FORMAT=(\"date\" \"snapshot\" \"type\" \"description\")/GRUB_BTRFS_TITLE_FORMAT=(\"description\" \"date\")/" /etc/default/grub-btrfs/config
sed -i 's/MODULES=()/MODULES=(btrfs)/' /etc/mkinitcpio.conf
sed -i 's|^HOOKS=.*|HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont plymouth block resume filesystems fsck btrfs)|' /etc/mkinitcpio.conf
plymouth-set-default-theme manjaro
update-grub
mkinitcpio -P
clear
echo ""
echo "##################################################"
echo "##    УСТАНОВКА БАЗОВОЙ СИСТЕМЫ ЗАВЕРШЕНА       ##"
echo "##         И ГОТОВА К ИСПОЛЬЗОВАНИЮ.            ##"
echo "##  ПРИ ЖЕЛАНИИ ВЫ МОЖЕТЕ ВЫЙТИ ИЗ УСТАНОВЩИКА, ##"
echo "##         ЛИБО ПРОДОЛЖИТЬ УСТАНОВКУ.           ##"
echo "##################################################"
echo ""






# ########################################################
# ## 🔐 БЛОК 10: HOSTNAME И ПАРОЛЬ ROOT (chroot) #########
# ########################################################
#
# Зачем: Настройка имени системы и пароля root.
# Важно: Без этого система не загрузится корректно.





clear
echo "Sony" > /etc/hostname
echo "127.0.0.1   localhost" > /etc/hosts
echo "::1         localhost" >> /etc/hosts
echo "127.0.1.1   Sony.localdomain   Sony" >> /etc/hosts
clear
echo ""
echo "###################################"
echo "## <<<  СОЗДАЙТЕ ПАРОЛЬ ROOT >>> ##"
echo "###################################"
echo ""
passwd
clear
echo ""
echo "##############################################"
echo "## <<<  НАСТРОЙКА ROOT И HOST ЗАВЕРШЕНА >>> ##"
echo "##############################################"
echo ""






# #######################################################
# ## 👤 БЛОК 11: ПОЛЬЗОВАТЕЛЬ И SUDO (chroot) ###########
# #######################################################
#
# Зачем: Создание пользователя и настройка sudo.
# Важно: Без wheel — sudo не будет работать.





clear
useradd forename -m -c "User Name" -s /bin/bash
usermod -aG wheel,users forename
sed -i s/'# %wheel ALL=(ALL:ALL) ALL'/'%wheel ALL=(ALL:ALL) ALL'/g /etc/sudoers
sed -i '/^%wheel ALL=(ALL:ALL) ALL$/a %forename ALL=(ALL:ALL) ALL' /etc/sudoers
clear
echo ""
echo "###########################################"
echo "## <<<  СОЗДАЙТЕ ПАРОЛЬ ПОЛЬЗОВАТЕЛЯ >>> ##"
echo "###########################################"
echo ""
passwd forename
clear
echo ""
echo "###############################################"
echo "## <<<  НАСТРОЙКА ПОЛЬЗОВАТЕЛЯ ЗАВЕРШЕНА >>> ##"
echo "###############################################"
echo ""







# ############################################
# ## УСТАНОВКА VIRTUALBOX (chroot) ###########
# ############################################
#
# Зачем: Настройка интеграции с VirtualBox.
# Важно: Только если установка в VirtualBox.





clear
pacman -S --noconfirm virtualbox-guest-utils
modprobe -a vboxguest vboxsf vboxvideo
systemctl enable vboxservice.service
echo "vboxguest vboxsf vboxvideo" > /etc/modules-load.d/virtualbox.conf
update-grub
mkinitcpio -P
usermod -aG vboxsf forename
clear
echo ""
echo "#############################################"
echo "## <<<  НАСТРОЙКА VIRTUALBOX ЗАВЕРШЕНА >>> ##"
echo "#############################################"
echo ""







# #######################################################
# ## 🧱 БЛОК 12: ВЫХОД ИЗ УСТАНОВКИ #####################
# #######################################################
#
# Зачем: Завершение установки, отмонтирование, выключение.
# Важно: Выполняется после chroot.



# Выход из chroot
exit


# Отмонтирование разделов диска
umount -R /mnt
swapoff -a
poweroff



# Очистка конфигурации ssh соединения
# rm -r .ssh/  # Раскомментировать, если нужно очистить SSH-сессию
