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





## ################################################################
# ## 🔐 БЛОК 1: ОПТИМИЗАЦИЯ SSH (ТОЛЬКО ПРИ УСТАНОВКЕ ЧЕРЕЗ SSH) ##
# #################################################################
#
# Зачем: Ускорение и стабильность при удалённой установке.
# Важно: Только если вы подключены по SSH. Необязательно при локальной установке.
# Эффект: Уменьшение задержек, отключение DNS, ускорение сессии.





clear
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sed -i 's/^#*Compression .*/Compression yes/' /etc/ssh/sshd_config
sed -i 's/^#*TCPKeepAlive .*/TCPKeepAlive yes/' /etc/ssh/sshd_config
sed -i 's/^#*ClientAliveInterval .*/ClientAliveInterval 60/' /etc/ssh/sshd_config
sed -i 's/^#*ClientAliveCountMax .*/ClientAliveCountMax 3/' /etc/ssh/sshd_config
sed -i 's/^#*UseDNS .*/UseDNS no/' /etc/ssh/sshd_config
sed -i 's/^#*MaxStartups .*/MaxStartups 10:30:100/' /etc/ssh/sshd_config
sed -i 's/^#*Ciphers .*/Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com/' /etc/ssh/sshd_config
systemctl restart sshd
clear
echo ""
echo "#####################################"
echo "## <<< НАСТРОЙКА SSH ЗАВЕРШЕНА >>> ##"
echo "#####################################"
echo ""
# 5. Проверка изменений
echo "Текущая конфигурация:"
grep -E 'Compression|TCPKeepAlive|ClientAlive|UseDNS|MaxStartups|Ciphers' /etc/ssh/sshd_config
echo ""






##########################################################
# ## ⚙️ БЛОК 2: ПОДГОТОВКА LIVE-СРЕДЫ ####################
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
# ## 🔍 БЛОК 3: ДИАГНОСТИКА ОБОРУДОВАНИЯ ###############
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
# ## 🔧 БЛОК 4: НАСТРОЙКА ПЕРЕМЕННЫХ (ОБЯЗАТЕЛЬНО!) ######
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
#             Имя                #  login	                #
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
# ## 🗂️ БЛОК 5: РАЗМЕТКА ДИСКА (GPT + EFI) #######
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
# ## 💾 БЛОК 6: ФОРМАТИРОВАНИЕ И МОНТИРОВАНИЕ ###########
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
# ## 🧱 БЛОК 7: УСТАНОВКА БАЗОВЫХ ПАКЕТОВ ###############
# ########################################################
#
# Зачем: Установка минимальной системы и переход в chroot.
# Важно: После этого — вход в chroot.
# Включает: base, btrfs, nano, pacman-contrib, curl.





clear
basestrap /mnt base linux612 linux-firmware-meta
basestrap /mnt manjaro-keyring
basestrap /mnt btrfs-progs
basestrap /mnt amd-ucode
basestrap /mnt memtest86+-efi
basestrap /mnt sudo
basestrap /mnt nano manjaro-zsh-config
basestrap /mnt pacman-contrib curl
basestrap /mnt mkinitcpio-openswap
fstabgen -pU /mnt >> /mnt/etc/fstab
mount --bind /dev /mnt/dev
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys
mount --bind /sys/firmware/efi/efivars /mnt/sys/firmware/efi/efivars
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
# ## 🔁 БЛОК 8: НАСТРОЙКА ВНУТРИ СИСТЕМЫ (chroot) #######
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






# #######################################################
# ## 🖋️ БЛОК 9: НАСТРОЙКА NANO (chroot) #################
# #######################################################
#
# Зачем: Глубокая настройка редактора nano.
# Включает: Цвета, подсветку, автоотступы, табы, softwrap.





clear
sed -i 's/# set autoindent/set autoindent/g' /etc/nanorc
sed -i 's/# set constantshow/set constantshow/g' /etc/nanorc
sed -i 's/# set indicator/set indicator/g' /etc/nanorc
sed -i 's/# set linenumbers/set linenumbers/g' /etc/nanorc
sed -i 's/# set multibuffer/set multibuffer/g' /etc/nanorc
sed -i 's/# set quickblank/set quickblank/g' /etc/nanorc
sed -i 's/# set smarthome/set smarthome/g' /etc/nanorc
sed -i 's/# set softwrap/set softwrap/g' /etc/nanorc
sed -i 's/# set tabsize 8/set tabsize 4/g' /etc/nanorc
sed -i 's/# set tabstospaces/set tabstospaces/g' /etc/nanorc
sed -i 's/# set trimblanks/set trimblanks/g' /etc/nanorc
sed -i 's/# set unix/set unix/g' /etc/nanorc
sed -i 's/# set wordbounds/set wordbounds/g' /etc/nanorc
sed -i 's/# set titlecolor bold,white,magenta/set titlecolor bold,white,magenta/g' /etc/nanorc
sed -i 's/# set promptcolor black,yellow/set promptcolor black,yellow/g' /etc/nanorc
sed -i 's/# set statuscolor bold,white,magenta/set statuscolor bold,white,magenta/g' /etc/nanorc
sed -i 's/# set errorcolor bold,white,red/set errorcolor bold,white,red/g' /etc/nanorc
sed -i 's/# set spotlightcolor black,orange/set spotlightcolor black,orange/g' /etc/nanorc
sed -i 's/# set selectedcolor lightwhite,cyan/set selectedcolor lightwhite,cyan/g' /etc/nanorc
sed -i 's/# set stripecolor ,yellow/set stripecolor ,yellow/g' /etc/nanorc
sed -i 's/# set scrollercolor magenta/set scrollercolor magenta/g' /etc/nanorc
sed -i 's/# set numbercolor magenta/set numbercolor magenta/g' /etc/nanorc
sed -i 's/# set keycolor lightmagenta/set keycolor lightmagenta/g' /etc/nanorc
sed -i 's/# set functioncolor magenta/set functioncolor magenta/g' /etc/nanorc
sed -i 's/# include \/usr\/share\/nano\/\*\.nanorc/include \/usr\/share\/nano\/\*\.nanorc/g' /etc/nanorc
sed -i 's/# include \/usr\/share\/nano\/\*\.nanorc/include \/usr\/share\/nano\/\*\.nanorc/g' /etc/nanorc
clear
echo ""
echo "######################################"
echo "## <<< НАСТРОЙКА NANO ЗАВЕРШЕНА >>> ##"
echo "######################################"
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
useradd login -m -c "User Name" -s /bin/bash
usermod -aG wheel,users login
sed -i s/'# %wheel ALL=(ALL:ALL) ALL'/'%wheel ALL=(ALL:ALL) ALL'/g /etc/sudoers
sed -i '/^%wheel ALL=(ALL:ALL) ALL$/a %login ALL=(ALL:ALL) ALL' /etc/sudoers
clear
echo ""
echo "###########################################"
echo "## <<<  СОЗДАЙТЕ ПАРОЛЬ ПОЛЬЗОВАТЕЛЯ >>> ##"
echo "###########################################"
echo ""
passwd login
clear
echo ""
echo "###############################################"
echo "## <<<  НАСТРОЙКА ПОЛЬЗОВАТЕЛЯ ЗАВЕРШЕНА >>> ##"
echo "###############################################"
echo ""






# #######################################################
# ## 🔧 БЛОК 12: УСТАНОВКА ЯДРА, GRUB, MKINITCPIO #######
# #######################################################
#
# Зачем: Настройка загрузчика и initramfs.
# Включает: GRUB, grub-btrfs, plymouth, resume из swap.





clear
pacman -Syy
pacman -S --noconfirm grub grub-btrfs grub-theme-manjaro update-grub os-prober plymouth plymouth-theme-manjaro efibootmgr
pacman -S --noconfirm networkmanager wpa_supplicant wireless_tools
pacman -S --noconfirm openssh
systemctl enable NetworkManager.service sshd.service
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
usermod -aG vboxsf login
clear
echo ""
echo "#############################################"
echo "## <<<  НАСТРОЙКА VIRTUALBOX ЗАВЕРШЕНА >>> ##"
echo "#############################################"
echo ""





# ######################################################
# ## 🌌 БЛОК 13: УСТАНОВКА ГРАФИЧЕСКОЙ СРЕДЫ ###########
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
# "=====  Системные библиотеки, утилиты и интерпретаторы ====="
pacman -S --noconfirm glibc-locales man-db man-pages sudo less vi nano nano-syntax-highlighting which diffutils rsync wget texinfo logrotate sysfsutils perl python-pillow python-pip python-pyqt5 python-pysmbc python-reportlab s-nail dmidecode lib32-libcanberra libcanberra xdg-user-dirs xdg-utils
# "=====  Мониторинг, отладка и информация о системе ====="
pacman -S --noconfirm htop powertop cpupower inxi fastfetch
# "=====  Управление дисками, разделами и файловыми системами ====="
pacman -S --noconfirm btrfs-progs dosfstools e2fsprogs exfatprogs f2fs-tools jfsutils xfsprogs ntfs-3g cryptsetup device-mapper lvm2 mdadm dmraid udisks2 udiskie
# "=====  Сетевые утилиты, менеджеры и сервисы ====="
pacman -S --noconfirm networkmanager networkmanager-l2tp networkmanager-openconnect networkmanager-openvpn networkmanager-vpnc wpa_supplicant wireless-regdb openssh nfs-utils avahi nss-mdns dnsmasq inetutils samba sshfs modemmanager
# "=====  Звук, видео, кодеки (ALSA, PipeWire, GStreamer, VLC) ====="
pacman -S --noconfirm alsa-firmware alsa-utils manjaro-alsa manjaro-pipewire sof-firmware gst-libav gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly phonon-qt6-vlc vlc ffmpeg ffmpegthumbs libdvdcss
# "=====  Графическая среда KDE Plasma (ядро и основные компоненты) ====="
pacman -S --noconfirm plasma-desktop plasma-workspace plasma-workspace-wallpapers kdeplasma-addons kwin kscreen kscreenlocker kwrited kwayland-integration breeze5 breeze-gtk kde-gtk-config
# "=====  Интеграция и апплеты KDE Plasma ====="
# Добавлен пропущенный пакет kaccounts-providers
pacman -S --noconfirm plasma-nm plasma-pa plasma-systemmonitor plasma-thunderbolt plasma-browser-integration powerdevil bluedevil kdeconnect xdg-desktop-portal-kde kaccounts-providers
# "=====  Системные настройки и утилиты KDE ====="
pacman -S --noconfirm systemsettings kinfocenter khelpcenter kscreenlocker kgamma kwallet-pam kwalletmanager ksshaskpass ksystemlog sddm sddm-breath-theme sddm-kcm
# "=====  Приложения и утилиты KDE ====="
# Добавлены пропущенные пакеты firefox, print-manager
pacman -S --noconfirm dolphin dolphin-plugins konsole kate kcalc gwenview okular ark spectacle skanlite kamera elisa filelight unarchiver 7zip kfind keditbookmarks milou yakuake print-manager
# "=====  Конфигурация и настройка KDE ====="
pacman -S --noconfirm kdenetwork-filesharing kdegraphics-thumbnailers kmenuedit keditbookmarks plymouth-kcm
# "=====  Дополнительные модули и поддержка форматов KDE/Qt ====="
pacman -S --noconfirm kimageformats audiocd-kio kio-extras

# "=====  Шрифты и темы оформления ====="
pacman -S --noconfirm adobe-source-sans-fonts noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-dejavu ttf-droid ttf-inconsolata ttf-indic-otf ttf-liberation terminus-font papirus-icon-theme gnome-themes-extra
# "=====  GTK и Qt библиотеки и модули ====="
pacman -S --noconfirm gtk3 gtkmm3 lib32-mesa lib32-mesa-utils mesa-utils libva-intel-driver lib32-libva-intel-driver qt6-imageformats qt6-virtualkeyboard
# "=====  Утилиты и настройки Manjaro ====="
pacman -S --noconfirm manjaro-hello manjaro-kde-settings manjaro-application-utility manjaro-browser-settings manjaro-gstreamer manjaro-release manjaro-settings-manager-knotifier manjaro-system manjaro-zsh-config manjaro-modem manjaro-printer
# "=====  Обслуживание системы, безопасность, виртуализация ====="
pacman -S --noconfirm mhwd mhwd-db acpi acpid b43-fwcutter fwupd sbctl open-vm-tools virtualbox-guest-utils qemu-guest-agent spice-vdagent udev-usb-sync usbutils usb_modeswitch
# "=====  Дополнительные утилиты и поддержка периферии ====="
# Добавлен пропущенный пакет ntp
pacman -S --noconfirm mtpfs perl-file-mimeinfo poppler-data ntp numlockx power-profiles-daemon ecryptfs-utils cronie
# "=====  X Window System и драйвера ввода ====="
pacman -S --noconfirm xorg-server xorg-xinit xorg-twm xorg-xkill xorg-mkfontscale xf86-input-elographics xf86-input-evdev xf86-input-libinput xf86-input-vmmouse xf86-input-void
# "=====  Приложения ====="
pacman -S --noconfirm firefox timeshift timeshift-autosnap-manjaro micro
# "=====  Менеджер пакетов Pamac ====="
pacman -S --noconfirm pamac-cli pamac-gtk3 pamac-tray-icon-plasma libpamac-flatpak-plugin
# "===== ЭТАП 21: Включение ключевых системных сервисов ====="
systemctl enable bluetooth
systemctl enable cups
systemctl enable avahi-daemon
systemctl enable ModemManager
systemctl enable sshd
systemctl enable sddm
systemctl enable power-profiles-daemon
systemctl enable udisks2
systemctl enable accounts-daemon
systemctl enable acpid
update-grub
mkinitcpio -P
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
# Основные компоненты GNOME
pacman -S --noconfirm gnome-shell gnome-session gnome-settings-daemon
pacman -S --noconfirm gnome-control-center gnome-backgrounds gnome-menus gnome-user-docs gnome-color-manager
pacman -S --noconfirm nautilus gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd gnome-keyring
pacman -S --noconfirm gnome-system-monitor gnome-logs gnome-disk-utility baobab
pacman -S --noconfirm epiphany gnome-connections gnome-remote-desktop gnome-maps
pacman -S --noconfirm evince gnome-text-editor gnome-calculator gnome-font-viewer
pacman -S --noconfirm gnome-calendar gnome-contacts gnome-clocks gnome-weather tecla orca
pacman -S --noconfirm gnome-characters gnome-tour gnome-user-share sushi decibels malcontent grilo-plugins yelp gnome-console
# Центр программ
pacman -S --noconfirm gnome-software
# Дисплейный менеджер
pacman -S --noconfirm gdm
# Порталы и интеграция
pacman -S --noconfirm xdg-desktop-portal-gnome xdg-user-dirs-gtk
# Медиа сервер
pacman -S --noconfirm rygel
#### gnome-extra и дополнительные пакеты Manjaro для GNOME ####
pacman -S --noconfirm dconf-editor
pacman -S --noconfirm file-roller ghex d-spy
pacman -S --noconfirm gnome-sound-recorder
pacman -S --noconfirm gnome-tweaks
pacman -S --noconfirm endeavour
# Утилиты просмотра эскизов
pacman -S --noconfirm tumbler ffmpegthumbnailer poppler-glib ffmpeg-audio-thumbnailer
# Простой просмотрщик изображений
pacman -S --noconfirm ristretto
# Дополнительные пакеты Manjaro, подходящие для GNOME
pacman -S --noconfirm manjaro-gnome-extension-settings manjaro-browser-settings manjaro-settings-manager-notifier manjaro-hello
pacman -S --noconfirm manjaro-alsa manjaro-pipewire
pacman -S --noconfirm manjaro-gstreamer
pacman -S --noconfirm manjaro-printer manjaro-modem
pacman -S --noconfirm gnome-firmware
pacman -S --noconfirm gnome-mines iagno quadrapassel
pacman -S --noconfirm gnome-chess
pacman -S --noconfirm lollypop # Аудиоплеер
pacman -S --noconfirm gthumb # Просмотрщик изображений
pacman -S --noconfirm snapshot # Камера
pacman -S --noconfirm collision # Проверка контрольных сумм
pacman -S --noconfirm fragments # BitTorrent клиент
pacman -S --noconfirm webapp-manager # Менеджер веб-приложений
# Расширения GNOME из Manjaro
pacman -S --noconfirm gnome-shell-extension-gsconnect gnome-shell-extension-legacy-theme-auto-switcher
# Дополнительные утилиты
pacman -S --noconfirm deja-dup # Резервное копирование
pacman -S --noconfirm gufw # Файрволл
# Текстовые редакторы и терминалы (если не входят в базовый набор)
pacman -S --noconfirm nano-syntax-highlighting
# Утилиты файлового менеджера
pacman -S --noconfirm nautilus-admin nautilus-empty-file nautilus-open-any-terminal
# Сеть
pacman -S --noconfirm networkmanager-openconnect networkmanager-openvpn networkmanager-strongswan networkmanager-vpnc network-manager-sstp
# Включаем GDM
systemctl enable gdm
# Отключаем учетную запись root в GUI (по желанию)
echo "[User]" > /var/lib/AccountsService/users/root
echo "SystemAccount=true" >> /var/lib/AccountsService/users/root
# Обновляем initramfs
mkinitcpio -P
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






# #######################################################
# ## 🧱 БЛОК 16: ВЫХОД ИЗ УСТАНОВКИ #####################
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
