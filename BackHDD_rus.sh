#!/bin/bash
#
#   Alexander Stepanov (c) 2016                    mailto: alpumba@gmail.com
#
###############################################################################
#
#                          SCRIPT FOR BACKING UP DATA
#
###############################################################################

set -o nounset
set -o errexit

FILE_LIST="./filelist.lst"  # Список команд и директорий-источников для бэкапа
DESTINATION=""              # Директория назначения (из файла)
MODE="TAR"                  # Режим архивации (по умолчанию TAR без компрессии)
UPD_ARCH="TRUE"             # Режим работы с архивами ZIP и 7Z (по умолчанию обновлять существующие)
QUIET_MODE="OFF"            # Тихий режим работы с выводом минимума информации на экран
ARCH_ON_SUBDIR="OFF"        # Режим создания архива на каждую поддиректорию в указанном источнике
MESSAGE=""                  # Текст сообщения для вызова функций PrintError & PrintOK

readonly Bold="\e[1m"       # Жирный шрифт
readonly _Bold="\e[21m"     # Отмена жирного шрифта на экране терминала
readonly ResetCol="\e[0m"   # Возврат к первоначальным настройкам шрифтов и цветов терминала
readonly DimCol="\e[2m"     # Затемненный цвет шрифта
readonly _DimCol="\e[22m"   # Отмена затемнения шрифта
readonly Under="\e[4m"      # Подчеркнутый текст
readonly _Under="\e[24m"    # Отмена подчеркнутого текста
readonly DefColor="\e[39m"  # Цвет шрифта в терминале по умолчанию
readonly Red="\e[31m"       # Красный
readonly Green="\e[32m"     # Зеленый
readonly Yellow="\e[33m"    # Желтый

PrintOK() {
    if [[ "$QUIET_MODE" == "OFF" ]]; then echo -e "$Bold$Green[  OK  ] $ResetCol$MESSAGE"; fi
}

PrintArchOK() {
    if [[ "$QUIET_MODE" == "OFF" ]]; then echo -e "$Bold$Green[  OK  ] $ResetColСоздан $ARCH_NAME"; fi    
}

PrintError() {
    echo -e "$Bold$Red[Ошибка] $ResetCol$MESSAGE"
}

PrintArchError() {
    echo -e "$Bold$Red[Ошибка] НЕ СОЗДАН $ARCH_NAME,\nисточник: $(pwd)$ResetCol"
}

PrintInfo() {
    if [[ "$QUIET_MODE" == "OFF" ]]; then echo -e "$Bold$Yellow[ ИНФО ] $MESSAGE$ResetCol"; fi
}

FN_Print_Help() {    
echo -e $Bold\
"_______________________________________________________________________________\n\n"\
"  Alexander Stepanov (c) 2016                    mailto: alpumba@gmail.com\n"\
"_______________________________________________________________________________\n"$_Bold\
"Скрипт работает совместно с файлом "$Bold$Under"filelist.lst"$_Under$_Bold" (имя и путь к файлу могут быть\n"\
"переопределены через ключ командной строки -f=... или --filelist=...) и служит\n"\
"для резервного копирования перечисленных каталогов в управляющем файле-списке\n"\
"с использованием архиватора TAR, либо простой компрессии в ZIP или 7Z.\n"\
"Для TAR также предусмотрен выбор различных алгоритмов компрессии через параметр\n"\
"!MODE=..., обратите внимание, по умолчанию используется TAR без компрессии.\n"\
"Есть режим создания отдельного архива на каждую поддиректорию в указанной папке\n"\
"(вид архивации при этом по-прежнему определяется параметром !MODE=...).\n\n"\
"P.S. Скрипт писался сугубо для личных нужд исходя из своих потребностей и\n"\
"поставляется \"как есть\". Критика по делу, коммментарии, предложения и\n"\
"дополнения приветствуются! Спасибо за проявленный интерес!\n"\
$Bold$Under"Параметры (аргументы) командной строки скрипта:\n"$_Under\
"-q или --quiet"$_Bold"    Тихий режим. Минимальный вывод на экран (выкл. по умолчанию)\n"\
$Bold"-h или --help"$_Bold"     Вывод информации по работе со скриптом\n"\
$Bold"-f или --filelist=путь_к_файлу"$_Bold" Переопределяет местоположение и имя\n"\
"                  файла-списка директорий подлежщих архивированию\n\n"\
$Bold"_______________________________________________________________________________\n\n"\
"             Структура управляющего файла-списка для архивации\n"\
"_______________________________________________________________________________\n\n"\
"Зарезервированные символы (должны быть первым символом в строке): 
'#' (решетка)"$_Bold" - все что после воспринимается как комментарий (игнорируется)\n\n"\
$Bold"'!' (восклицательный знак)"$_Bold" - признак параметра (команды), см. ниже:\n\n"\
$Bold"!DESTINATION=..."$_Bold" - Путь к директории назначения (куда копировать)\n"\
$Bold$Under"Режимы архивации с использованием TAR\n"$_Under\
$Red"Для TAR архивов в этой версии скрипта недоступно обновление\n"\
"существующих архивов при изменении файлов в источнике.\n"$DefColor\
"Т.е. TAR всегда создается заново!\n"$_Bold\
$Bold"!MODE"$_Bold" - режим (если не указан, то "$Green"по умолчанию TAR без сжатия"$DefColor")\n"\
$Bold"!MODE=TAR"$_Bold" - TAR без сжатия (максимальная скорость, огромный размер)\n"\
$Bold"!MODE=TZO"$_Bold" - TAR c сжатием LZOP "$Yellow"(сверхбыстро, большой размер)"$DefColor"  (!)\n"\
$Bold"!MODE=TGZ"$_Bold" - TAR с сжатием GZIP "$Yellow"(очень быстро, хорошее сжатие)"$DefColor" (!)\n"\
$Bold"!MODE=TBZ"$_Bold" - TAR с сжатием BZ2  (средне, хорошее сжатие)\n"\
$Bold"!MODE=T7Z"$_Bold" - TAR с сжатием 7Z   "$Yellow"(долго, макс. сжатие)"$DefColor"          (!)\n"\
$Bold"!MODE=TLZ"$_Bold" - TAR с сжатием LZMA "$Yellow"(очень долго, хорошее сжатие)"$DefColor"  (!)\n"\
$Bold"!MODE=TXZ"$_Bold" - TAR с сжатием XZ   (очень долго, хорошее сжатие)\n\n"\
$Bold$Under"Режимы архивирования БЕЗ использования TAR\n"$_Under\
"!UPD_ARCH=TRUE (default)"$_Bold" или FALSE "$Red"ТОЛЬКО ДЛЯ ZIP и 7Z архивов:\n"$DefColor\
"          TRUE - обновлять содержимое архива при изменении файлов источника\n"\
"          FALSE- перезаписывать (создавать заново)\n"\
$Bold"!MODE=ZIP"$_Bold" - сжатие в ZIP (в три раза дольше чем TGZ при схожем размере)\n"\
$Bold"!MODE=7Z"$_Bold"  - сжатие в 7Z (почти полный аналог T7Z по скорости и размеру)\n\n"\
$Bold$Under"Специальные возможности\n"$_Under\
"!MODE=COPY"$_Bold"- простое копирование указанного каталога из источника в назначение\n\n"\
$Bold$Under"Источник для архивирования\n"$ResetCol\
"Указываем абсолютные пути к директориям - источникам для архивации\n"\
"по одной директории на строку\n\n"\
$Bold"!ARCH_ON_SUBDIR=OFF (default) или ON"$_Bold" - режим создания отдельного архива на\n"\
"                    каждую поддиректорию из папки источника (по умолчанию OFF)\n"\
$Red"                    ВНИМАНИЕ!!! Использовать с умом и очень осторожно!!!\n"$ResetCol\
"                    При ON не будут созданы архивы для скрытых подкаталогов\n"\
"                    директории источника! Убеитесь что скрытых нет!\n\n"\
$Bold"_______________________________________________________________________________\n\n"\
"                            ПРИМЕР ФАЙЛА filelist.lst\n"\
"_______________________________________________________________________________\n\n"$_Bold\
$DimCol"# Комментарий внутри filelist.lst\n"$_DimCol\
"!DESTINATION=/mnt/MyBackup/\n"\
$DimCol"# !MODE не указан, следовательно /home/test1/ и /home/test2/ будут\n"\
"# заархивированы в TAR без компрессии (равносильно указанию !MODE=TAR)\n"$_DimCol\
"/home/test1/\n"\
"/home/test2/\n"\
"!MODE=COPY\n"\
$DimCol"# /home/test3/photos/ просто копируется целиком в назначение (команда cp)\n"$_DimCol\
"/home/test3/photos/\n"\
"!MODE=ZIP\n"\
$DimCol"# /home/test3/ForWindows/ сжимается в стандартный ZIP-архив (без тарбола)\n"$_DimCol\
"/home/test3/ForWindows/\n\n"\
$Bold$Under"ВНИМАНИЕ! Файл всегда должен завершаться пустой строкой!"$ResetCol
}

###############################################################################
#
#  СОЗДАТЬ АРХИВ С УЧЕТОМ НАСТРОЕК ВЫБРАННЫХ ПОЛЬЗОВАТЕЛЕМ
#
#  При вызове должно быть корректное состояние SRC_PATH (источник)
#  и DESTINATION (полный путь к папке назначения)
#
###############################################################################
MakeArchiveBySrcPath() {
    local FULL_BACKUP_PATH=""         # Полный путь для бэкапа
    # Проверяем корректность параметров
    if [[ "$DESTINATION" == "" ]]
        then
        MESSAGE=$(echo "Перечню путей к каталогам подлежащих обработке, указанных в filelist.lst,\n"\
        "должен предшествовать обязательный параметр !DESTINATION=\...,\n"\
        "определяющий путь для сохранения результирующего набора файлов (архива)!")
        PrintError
        exit
    fi

    if ! ( cd "$SRC_PATH" &>/dev/null ); then
        MESSAGE=$(echo "Не найден источник: $SRC_PATH")
        PrintError
        continue
    fi

    # Избавляемся от лишнего слеша (при наличии) в полном пути для бэкапа
    if [[ ${DESTINATION: -1} == "/" ]]
        then FULL_BACKUP_PATH="${DESTINATION:0:-1}$SRC_PATH"
        else FULL_BACKUP_PATH="$DESTINATION$/SRC_PATH"
    fi

    # Выбрасываем из полного пути последнюю папку для режима архивации подпапок
    if [[ "$ARCH_ON_SUBDIR" == "ON" ]]
        then FULL_BACKUP_PATH=$(echo "${FULL_BACKUP_PATH%/?*}")
    fi

    # Добавим слеш в конец пути при отсутствии
    if [[ ${FULL_BACKUP_PATH: -1} != "/" ]]
        then FULL_BACKUP_PATH="$FULL_BACKUP_PATH/"
    fi    

    # Попытка войти в целевую директорию для бэкапа, проверка ее существования и прав.
    if ! ( cd "$FULL_BACKUP_PATH" &>/dev/null )
        then
        if ! ( ( mkdir -p "$FULL_BACKUP_PATH" &>/dev/null ) && ( cd "$FULL_BACKUP_PATH" &>/dev/null ) )
            then
            MESSAGE=$(echo "Не удается перейти в целевую директорию:\n$FULL_BACKUP_PATH\n"\
            "$Yellow Возможно необходимо запустить скрипт от имени суперпользователя?$DefColor")
            PrintError
            exit
        fi
    fi

    # Все проверки пройдены, все ОК, работаем в соответствии с MODE
    case $MODE in
        TAR|tar)
    ARCH_NAME=$(echo "$FULL_BACKUP_PATH$(basename "$SRC_PATH").tar")
    if cd "$SRC_PATH" && ( tar -cf "$ARCH_NAME" --one-file-system --exclude-backups --ignore-failed-read . &>/dev/null )
        then PrintArchOK
    else PrintArchError
    fi
        ;; #------------------------------------------------------
        TZO|tzo)
    ARCH_NAME=$(echo "$FULL_BACKUP_PATH$(basename "$SRC_PATH").tar.lzo")
    if cd "$SRC_PATH" && ( tar -cf "$ARCH_NAME" --lzop --one-file-system --exclude-backups --ignore-failed-read . &>/dev/null )
        then PrintArchOK
    else PrintArchError
    fi             
        ;; #------------------------------------------------------
        TGZ|tgz)
    ARCH_NAME=$(echo "$FULL_BACKUP_PATH$(basename "$SRC_PATH").tar.gz")
    if cd "$SRC_PATH" && ( tar -czf "$ARCH_NAME" --one-file-system --exclude-backups --ignore-failed-read . &>/dev/null )
        then PrintArchOK
    else PrintArchError
    fi
        ;; #------------------------------------------------------
        TBZ|tbz)
    ARCH_NAME=$(echo "$FULL_BACKUP_PATH$(basename "$SRC_PATH").tar.bz2")
    if cd "$SRC_PATH" && ( tar -cjf "$ARCH_NAME" --one-file-system --exclude-backups --ignore-failed-read . &>/dev/null )
        then PrintArchOK
    else PrintArchError
    fi
        ;; #------------------------------------------------------
        TLZ|tlz)
    ARCH_NAME=$(echo "$FULL_BACKUP_PATH$(basename "$SRC_PATH").tar.lzma")
    if cd "$SRC_PATH" && ( tar -cf "$ARCH_NAME" --lzma --one-file-system --exclude-backups --ignore-failed-read . &>/dev/null )
        then PrintArchOK
    else PrintArchError
    fi
        ;; #------------------------------------------------------
        TXZ|txz)
    ARCH_NAME=$(echo "$FULL_BACKUP_PATH$(basename "$SRC_PATH").tar.xz")
    if cd "$SRC_PATH" && ( tar -cJf "$ARCH_NAME" --one-file-system --exclude-backups --ignore-failed-read . &>/dev/null )
        then PrintArchOK
    else PrintArchError
    fi             
        ;; #------------------------------------------------------
        T7Z|t7z)
    ARCH_NAME=$(echo "$FULL_BACKUP_PATH$(basename "$SRC_PATH").tar.7z")
    [[ -f "$ARCH_NAME" ]] && rm "$ARCH_NAME" &>/dev/null                 
    if cd "$SRC_PATH" && ( tar -c --one-file-system --exclude-backups --ignore-failed-read . | 7z a -si "$ARCH_NAME" &>/dev/null )
        then PrintArchOK
    else PrintArchError
    fi
        ;; #------------------------------------------------------
        ZIP|zip)
    ARCH_NAME=$(echo "$FULL_BACKUP_PATH$(basename "$SRC_PATH").zip")
    if [[ $UPD_ARCH == "TRUE" ]]
        then                
        7z u -tzip "$ARCH_NAME" "$SRC_PATH" &>/dev/null && \
        ( MESSAGE=$(echo "Обновлен $ARCH_NAME"); PrintOK ) || \
        PrintArchError
    else
        [ -f "$ARCH_NAME" ] && rm "$ARCH_NAME"
        MESSAGE=$(echo "Пересоздан $ARCH_NAME")
        7z a -tzip "$ARCH_NAME" "$SRC_PATH" &>/dev/null && PrintOK || PrintArchError
    fi
        ;; #------------------------------------------------------
        7Z|7z)
    ARCH_NAME=$(echo "$FULL_BACKUP_PATH$(basename "$SRC_PATH").7z")
    if [[ $UPD_ARCH == "TRUE" ]]
        then
        7z u -t7z -myx7 "$ARCH_NAME" "$SRC_PATH" &> /dev/null && \
        ( MESSAGE=$(echo "Обновлен $ARCH_NAME"); PrintOK ) || \
        PrintArchError
    else
        [ -f "$ARCH_NAME" ] && rm "$ARCH_NAME"
        MESSAGE=$(echo "Пересоздан $ARCH_NAME")                    
        7z a -t7z -myx7 "$ARCH_NAME" "$SRC_PATH" &> /dev/null && PrintOK || PrintArchError                                    
    fi
        ;; #------------------------------------------------------
           # RCP???
           COPY|copy)
    cp -a -r -P -u --one-file-system "$SRC_PATH" "$FULL_BACKUP_PATH" &>/dev/null && \
    ( MESSAGE=$(echo "Скопировано $SRC_PATH в $FULL_BACKUP_PATH"); PrintOK ) || \
    ( MESSAGE=$(echo "Ошибка копирования $SRC_PATH в $FULL_BACKUP_PATH"); PrintError )
        ;; #------------------------------------------------------

        *)  echo "Неизвестный режим MODE=$MODE"
        ;; #------------------------------------------------------
    esac
}

# < ТОЧКА ВХОДА

##############################################################################
# Готовимся к работе, закатываем рукава и для начала
# разбираем переданные скрипту параметры (при их наличии)
for ARG in "$@"
do      
    case $ARG in
        --quiet|-q) # Тихий режим
            QUIET_MODE="ON"
        ;;
        --filelist=*|-f=*) # Переопределение файла-списка
            FILE_LIST=$(echo $ARG | awk 'BEGIN{FS="="} {print $2}')            
        ;;
        *) # На любую неизвестную команду (в том числе и на --help|-h) выводим справку
            FN_Print_Help
            exit
        ;;
    esac
done

# Выведем список всех параметров
[[ $QUIET_MODE == "OFF" ]] && echo -e $Yellow\
"------------------------------------------------------------------\n"\
"FILE_LIST=$FILE_LIST - Перечень команд и источников для бэкапа\n"\
"MODE=$MODE - Режим архивации\n"\
"UPD_ARCH=$UPD_ARCH - Режим работы с архивами ZIP и 7Z\n"\
"QUIET_MODE=$QUIET_MODE - режим вывода информации на экран\n"\
"ARCH_ON_SUBDIR=$ARCH_ON_SUBDIR - архив на каждую поддиректорию в источнике\n"\
"------------------------------------------------------------------"$ResetCol

if ! [ -s "$FILE_LIST" ]; then
    MESSAGE="Не найден или пустой файл $FILE_LIST со списком инструкций и директорий для резервного копирования!"
    PrintError
    exit
fi

###############################################################################
# Читаем по-очереди имена файлов из списка для копирования и работаем с ними
#
while read LineFromList
do
    # Это комментарий в файле (#) - не обрабатываем
    # эту проверку можно убрать, неизвестное и так не обрабатывается
    if [[ ${LineFromList:0:1} == '#' ]] ; then continue ; fi

    ###########################################################################
    # Проверяем является ли командой (!) и обрабатываем при необходимости
    if [[ ${LineFromList:0:1} == '!' ]]
        then
        case ${LineFromList:1} in
            # ========[ DESTINATION - путь КУДА сохранять архив]========
            DEST*) DESTINATION=$(echo $LineFromList | awk 'BEGIN{FS="="} {print $2}')
                   MESSAGE="DESTINATION=$DESTINATION"
                   PrintInfo
                ;;
            # ========[ MODE - выбор режима архивации ]========
            MODE*) MODE=$(echo $LineFromList | awk 'BEGIN{FS="="} {print $2}')
                   if [[ $MODE == "" ]]; then MODE="TAR"; fi;
                   MESSAGE="MODE=$MODE"
                   PrintInfo
                ;;
            # ========[ UPD_ARCH - режима перезаписи или обновления ]========
            UPD_ARCH*) UPD_ARCH=$(echo $LineFromList | awk 'BEGIN{FS="="} {print $2}')
                    if [[ $UPD_ARCH != "FALSE" ]]; then UPD_ARCH="TRUE"; fi;
                        MESSAGE="UPD_ARCH=$UPD_ARCH"
                        PrintInfo
                ;;
            # ===[ ARCH_ON_SUBDIR - режим архива на каждую поддиректорию ]===
            ARCH_ON_SUBDIR*)
                   ARCH_ON_SUBDIR=$(echo $LineFromList | awk 'BEGIN{FS="="} {print $2}')
                   if [[ "$ARCH_ON_SUBDIR" == "" ]]; then ARCH_ON_SUBDIR="OFF"; fi;
                   MESSAGE="ARCH_ON_SUBDIR=$ARCH_ON_SUBDIR"
                   PrintInfo
                ;;
            # ========[ МОЖЕТЕ ДОПИСАТЬ СВОИ ПАРАМЕТРЫ ]========
                *) MESSAGE="Неизвестная команда ${LineFromList:1} - логика не реализована..."
                PrintError
                ;;
        esac
        continue        
    fi

    ###########################################################################
    # Проверка на осмысленные данные из файла, если не путь, то есть
    # не начинается с '/', то переходим к следующей строке в файле
    if [[ ${LineFromList:0:1} != '/' ]]; then continue; fi

    # Обычный режим - один архив на источник
    if [[ "$ARCH_ON_SUBDIR" == "OFF" ]]; then
        SRC_PATH="$LineFromList"
        MakeArchiveBySrcPath
    else
        # Режим создания архива на каждую поддиректорию источника
        # ВНИМАНИЕ! Скрытые поддиректории не обрабатываются!!!
        cd "$LineFromList"            
        for SRC_PATH in *
        do
            if [ -d "$SRC_PATH" ] && ( [[ "$SRC_PATH" != "." ]] && [[ "$SRC_PATH" != ".." ]] )
                then
                    SRC_PATH=$PWD/$SRC_PATH
                    MakeArchiveBySrcPath
            fi
        done
    fi    
done < "$FILE_LIST"

###############################################################################
