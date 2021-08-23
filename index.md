# _hsh-rpm-into-appimage/Руководство_

_Принцип действия_

Скрипт пересобирает rpm пакет из sisyphus в формат appimage внутри окружения [hasher](https://www.altlinux.org/Hasher/%D0%A0%D1%83%D0%BA%D0%BE%D0%B2%D0%BE%D0%B4%D1%81%D1%82%D0%B2%D0%BE).

Rpm пакет скачивается из репозитория, и устанавливается внутрь hasher`а, после чего загруженный пакет распаковывается в директорию AppDir, которая потом будет паковаться в appimage.

Сборка appimage реализована при помощи [linuxdeploy](https://github.com/linuxdeploy/linuxdeploy), он загружается автоматически в директорию /tmp, linuxdeploy требует указания .desktop файла, исполняемого файла и иконки приложения. Поэтому скрипт ищет .desktop файл, и внутри него необходимые названия, после чего внутри окружения hasher запускается linuxdeploy с указанными файлами.

Также linuxdeploy поддерживает систему плагинов, добавляющие необходимые библиотеки фреймворков. Доступные плагины - qt, gtk, ncurses, gstreamer. При их указании, они автоматически загружаются и применяются.

_Установка_

Для установки нужно просто загрузить [скрипт](https://raw.githubusercontent.com/MasterTinka/hsh-rpm-into-appimage/main/hsh-rpm-into-appimage.sh) и сделать его исполняемым.

Предварительно нужно установить и настроить [hasher](https://www.altlinux.org/Hasher/%D0%A0%D1%83%D0%BA%D0%BE%D0%B2%D0%BE%D0%B4%D1%81%D1%82%D0%B2%D0%BE), в том числе настроить [монтирование /proc](https://www.altlinux.org/Hasher/%D0%A0%D1%83%D0%BA%D0%BE%D0%B2%D0%BE%D0%B4%D1%81%D1%82%D0%B2%D0%BE#%D0%9C%D0%BE%D0%BD%D1%82%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5_/proc).

_Использование_

Вывод help -

--package [package.rpm] specify the package to repackage

--plugin [plugin] specify the plugin to use

available plugins - qt gtk ncurses gstreamer

--apt-config [file] specify the apt configuration file for hasher

--path [/path/to/hasher] specify path for hasher

Обязательным является только параметр --package, остальные имеют значения по умолчанию.

--apt-config - /etc/apt/apt.conf

--path - /home/$USER/hasher

Директорию, указанную в параметре --path создавать не обязательно, скрипт попытается её создать автоматически.

Пример использования скрипта -

./hsh-rpm-into-appimage.sh --path /tmp/.private/leonid/hasher --package kde5-ktorrent --plugin qt

_Troubleshooting_

1. Ошибка &quot;Please, specify the package&quot; - пакет не указан, проверьте параметр --package

1. Ошибка &quot;Path to hasher doesn`t exist, please create it manually&quot;- скрипту не удалось создать директорию, указанную в параметре --path. Создайте её самостоятельно, или проверьте корректность указанной директории.

1. Ошибка &quot;Please, add allowed\_mountpoints=/proc in /etc/hasher-priv/system&quot; - см. по [ссылке](https://www.altlinux.org/Hasher/%D0%A0%D1%83%D0%BA%D0%BE%D0%B2%D0%BE%D0%B4%D1%81%D1%82%D0%B2%D0%BE#%D0%9C%D0%BE%D0%BD%D1%82%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5_%D1%84%D0%B0%D0%B9%D0%BB%D0%BE%D0%B2%D1%8B%D1%85_%D1%81%D0%B8%D1%81%D1%82%D0%B5%D0%BC_%D0%B2%D0%BD%D1%83%D1%82%D1%80%D0%B8_hasher).

1. Ошибка &quot;Package doesn`t exist, please, check it out&quot; - hsh-install не смог установить указанный пакет, проверьте его корректность.
