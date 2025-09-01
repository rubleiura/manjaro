# ################################################################
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
basestrap /mnt base base-devel
basestrap /mnt manjaro-keyring
basestrap /mnt btrfs-progs
basestrap /mnt amd-ucode
basestrap /mnt memtest86+-efi
basestrap /mnt nano micro manjaro-zsh-config
basestrap /mnt manjaro-settings-manager
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
# ## 🔁 БЛОК 8: НАСТРОЙКА ВНУТРИ СИСТЕМЫ (chroot) #######
# ########################################################
#
# Зачем: Настройка системы: локали, fstab, время, зеркала.
# Важно: Выполняется внутри chroot.
# Автоматизация: Временная зона по IP, зеркала по стране.





clear
sed -i 's/\S*subvol=\(\S*\)/subvol=\1,defaults/g'  /etc/fstab
sed -i s/'#ParallelDownloads'/'ParallelDownloads'/g /etc/pacman.conf
sed -i s/'ParallelDownloads = 5'/'ParallelDownloads = 15'/g /etc/pacman.conf
sed -i s/'#Color'/'Color'/g /etc/pacman.conf
sed -i '/^Color$/a VerbosePkgLists' /etc/pacman.conf
sed -i '/^Color$/a DisableDownloadTimeout' /etc/pacman.conf
sed -i '/^Color$/a ILoveCandy' /etc/pacman.conf
echo "KEYMAP=ru" > /etc/vconsole.conf
echo "FONT=cyr-sun16" >> /etc/vconsole.conf
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
sed -i "s/#ru_RU/ru_RU/" /etc/locale.gen
sed -i "s/#en_US/en_US/" /etc/locale.gen
locale-gen
export LANG=ru_RU.UTF-8
time_zone=$(curl -s https://ipinfo.io/timezone  )
ln -sf /usr/share/zoneinfo/$time_zone /etc/localtime
hwclock --systohc
pacman-mirrors --country all --api --protocols https --set-branch stable
pacman -Syy
pacman -S --noconfirm manjaro-release manjaro-system
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
pacman -S --noconfirm linux612 linux612-headers linux-firmware
pacman -S --noconfirm grub grub-btrfs efibootmgr os-prober
pacman -S --noconfirm networkmanager wpa_supplicant wireless_tools
pacman -S --noconfirm openssh
pacman -S --noconfirm plymouth plymouth-theme-manjaro
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
grub-mkconfig -o /boot/grub/grub.cfg
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






# #######################################################
# ## 🧰 БЛОК 13: СИСТЕМНЫЕ УТИЛИТЫ И WAYLAND (chroot) ###
# #######################################################
#
# Зачем: Установка системных утилит, PipeWire, шрифтов.
# Включает: Bluetooth, CUPS, xdg, PipeWire, Wayland.





clear
pacman -Syy
pacman -S --noconfirm haveged
systemctl enable haveged.service
pacman -S --noconfirm wget vim usbutils lsof dmidecode dialog zip unzip unrar p7zip lzop lrzip sudo mlocate less bash-completion
pacman -S --noconfirm dosfstools ntfs-3g btrfs-progs exfatprogs gptfdisk fuse2 fuse3 fuseiso nfs-utils cifs-utils
pacman -S --noconfirm cronie
systemctl enable cronie.service
pacman -S --noconfirm bluez bluez-utils manjaro-modem
systemctl enable bluetooth.service
sed -i 's/#AutoEnable=true/AutoEnable=true/g' /etc/bluetooth/main.conf
pacman -S --noconfirm cups cups-pdf ghostscript gsfonts manjaro-printer
systemctl enable cups.service
pacman -S --noconfirm xdg-utils xdg-user-dirs
xdg-user-dirs-update
pacman -S --noconfirm udisks2 udiskie polkit
pacman -S --noconfirm manjaro-alsa manjaro-pipewire wireplumber pipewire-alsa pipewire-pulse pipewire-jack pipewire-v4l2 pipewire-zeroconf alsa-utils
systemctl --global enable pipewire pipewire-pulse wireplumber
pacman -S --noconfirm manjaro-gstreamer gstreamer gst-plugins-{base,good,bad,ugly} gst-libav ffmpeg a52dec faac faad2 flac lame libdca libdv libmad libmpeg2 libtheora libvorbis wavpack x264 x265 xvidcore libdvdcss vlc taglib
pacman -S --noconfirm man-pages man-pages-ru
pacman -S --noconfirm ttf-dejavu noto-fonts noto-fonts-emoji ttf-inconsolata
pacman -S --noconfirm iproute2 inetutils dnsutils
pacman -S --noconfirm fastfetch hyfetch inxi
clear
# ========================================================
# УСТАНОВКА БАЗОВЫХ КОМПОНЕНТОВ WAYLAND И ГРАФИЧЕСКОЙ ПОДСИСТЕМЫ
# Включает: Mesa, Vulkan, Wayland, libinput, seatd
# ========================================================
pacman -S --noconfirm mesa vulkan-icd-loader libglvnd
pacman -S --noconfirm wayland wayland-protocols
pacman -S --noconfirm libinput libxkbcommon seatd
systemctl enable seatd.service  # Для управления правами доступа к GPU
mkinitcpio -P
clear
echo ""
echo "###############################################################"
echo "## <<<  УСТАНОВКА СИСТЕМНЫХ ПРОГРАММ И WAYLAND ЗАВЕРШЕНА >>> ##"
echo "###############################################################"
echo ""
echo "##############################################"
echo "## <<<  ВИДЕОКАРТЫ  ДАННОГО КОМПЬЮТЕРА  >>> ##"
echo "## <<< ВЫБЕРИТЕ ДРАЙВЕРА СОГЛАСНО ТЕСТУ >>> ##"
echo "##############################################"
echo ""
echo "Видеокарты:" && lspci -nn | grep -i 'vga' ; echo "Драйверы:" && lsmod | grep -iE 'nvidia|amdgpu|i915'
echo ""
echo ""






# ########################################################
# ## 🖥️ БЛОК 14: УСТАНОВКА ВИДЕО-ДРАЙВЕРА (chroot) #######
# ########################################################
#
# Зачем: Установка БАЗОВЫХ драйверов для минимальной работы графической среды Wayland
# Важно: Это минимальный набор для запуска графической оболочки
#         Полная настройка драйверов выполняется отдельно после установки системы
# ----------------------------------------------------------
# Минимальные драйверы:
#   • Intel:        vulkan-intel
#   • AMD:          vulkan-radeon
#   • NVIDIA:       Зависит о ядра (nvidia nvidia-utils для стандартного ядра)
#   • Виртуализация: virtualbox-guest-utils (для VirtualBox)
# ----------------------------------------------------------
# После установки системы выполните полную настройку драйверов:
# (см. отдельный файл с инструкцией Video drivers.)





# ############################################
# ## УСТАНОВКА VIRTUALBOX (chroot) ###########
# ############################################
#
# Зачем: Настройка интеграции с VirtualBox.
# Важно: Только если установка в VirtualBox.





clear
pacman -S --needed --noconfirm virtualbox-guest-utils
modprobe -a vboxguest vboxsf vboxvideo
systemctl enable vboxservice.service
echo "vboxguest vboxsf vboxvideo" > /etc/modules-load.d/virtualbox.conf
mkinitcpio -P
usermod -aG vboxsf $login
clear
echo ""
echo "#############################################"
echo "## <<<  НАСТРОЙКА VIRTUALBOX ЗАВЕРШЕНА >>> ##"
echo "#############################################"
echo ""






# ######################################################
# ## 🌌 БЛОК 15: УСТАНОВКА ГРАФИЧЕСКОЙ СРЕДЫ ###########
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
#### Plasma ####
pacman -Syy
pacman -S --noconfirm plasma-desktop plasma-workspace plasma-workspace-wallpapers kdeplasma-addons kwin libplasma plasma5support libkscreen
pacman -S --noconfirm systemsettings kinfocenter kde-gtk-config polkit-kde-agent sddm-kcm kmenuedit kdecoration kscreen
pacman -S --noconfirm plasma-browser-integration plasma-activities plasma-activities-stats milou plasma-integration
pacman -S --noconfirm powerdevil print-manager bluedevil plasma-nm plasma-pa
pacman -S --noconfirm plasma-firewall plasma-thunderbolt plasma-vault kscreenlocker kwallet-pam
pacman -S --noconfirm ksystemstats drkonqi plasma-systemmonitor libksysguard plasma-disks
pacman -S --noconfirm spectacle kgamma ksshaskpass kwrited kglobalacceld
pacman -S --noconfirm breeze breeze-gtk oxygen oxygen-sounds aurorae ocean-sound-theme qqc2-breeze-style
pacman -S --noconfirm discover flatpak-kcm
pacman -S --noconfirm kactivitymanagerd kpipewire layer-shell-qt
pacman -S --noconfirm kde-cli-tools plasma-sdk
pacman -S --noconfirm wacomtablet
pacman -S --noconfirm xdg-desktop-portal-kde plymouth-kcm
#### kde-applications ####
pacman -S --noconfirm falkon krdc krfb konversation kio-zeroconf kdenetwork-filesharing kio-gdrive
pacman -S --noconfirm elisa ffmpegthumbs kamoso krecorder kwave k3b audiocd-kio audex kdenlive
pacman -S --noconfirm gwenview kamera kcolorchooser kdegraphics-thumbnailers kimagemapeditor skanlite skanpage kolourpaint svgpart kgraphviewer
pacman -S --noconfirm ghostwriter ark okular kwordquiz kalk korganizer kate
pacman -S --noconfirm filelight ksystemlog sweeper partitionmanager kcron khelpcenter
pacman -S --noconfirm ark kcalc konsole kfind keditbookmarks kdf kcharselect kclock kruler kteatime ktimer yakuake dolphin dolphin-plugins kio-extras kio-admin kdialog kleopatra kgpg kwalletmanager accessibility-inspector
pacman -S --noconfirm kmag kmousetool kmouth kontrast
pacman -S --noconfirm colord-kde isoimagewriter signon-kwallet-extension markdownpart kweather lokalize qrca
# Дополнительные пакеты Manjaro для KDE
pacman -S --noconfirm manjaro-kde-settings manjaro-settings-manager-knotifier manjaro-hello manjaro-browser-settings pamac-tray-icon-plasma papirus-icon-theme
systemctl enable sddm.service
mkinitcpio -P
clear
echo ""
echo "#############################################"
echo "## <<<  УСТАНОВКА KDE PLASMA ЗАВЕРШЕНА >>> ##"
echo "#############################################"
echo ""






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
