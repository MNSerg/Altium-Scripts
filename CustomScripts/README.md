# CustomScripts — скрипты Altium Designer 20+

Набор скриптов DelphiScript для повседневных задач PCB/схемы. Примеры в репозитории (`!SCRIPTS`) не изменялись.

Параметры согласованы с заказчиком (см. [`QUESTIONS.md`](QUESTIONS.md) — вопросы закрыты).

## Установка

У каждого скрипта **своя папка** и **свой** `.PrjScr` с **одним** `.pas` (как в `!SCRIPTS/Fillet/Fillet.PrjScr`). Altium компилирует **все** `.pas` из проекта в **одно** пространство имён: общий `CustomScripts.PrjScr` со всеми модулями даёт `Identifier redeclared`.

Открывайте `CustomScripts/<Name>/<Name>.PrjScr`.

| Скрипт | Проект | Процедура Run Script |
| --- | --- | --- |
| Скругления трека | `CustomScripts/TrackCornerFillet/TrackCornerFillet.PrjScr` | `StartTrackCornerFillet` (`_StartTrackCornerFillet`) |
| DXF контуров | `CustomScripts/DxfOutlineExport/DxfOutlineExport.PrjScr` | `StartDxfOutlineExport` |
| Панелизация | `CustomScripts/Panelizer/Panelizer.PrjScr` | `StartPanelizer` |
| Десигнаторы схемы | `CustomScripts/SchDesignatorReset/SchDesignatorReset.PrjScr` | `StartSchDesignatorReset` |
| BOM CSV | `CustomScripts/BomExport/BomExport.PrjScr` | `StartBomExport` |
| Полигоны GND | `CustomScripts/GroundPolygons/GroundPolygons.PrjScr` | `StartGroundPolygons` |
| Мастер PCB | `CustomScripts/PcbWizard/PcbWizard.PrjScr` | `StartPcbWizard` |
| Десигнаторы на PCB | `CustomScripts/PlaceDesignators/PlaceDesignators.PrjScr` | `StartPlaceDesignators` |
| Offset треков | `CustomScripts/Offset/Offset.PrjScr` | `StartOffset` |
| Панель (тест фрезы) | `CustomScripts/PanelizerTest/PanelizerTest.PrjScr` | `StartPanelizerTest` |

1. **File → Open Project** и откройте нужный `CustomScripts/<Name>/<Name>.PrjScr` **или** добавьте каждый проект в **Preferences → Scripting System → Project Scripts**.
2. Запускайте **уникальную** процедуру `Start…` из таблицы (не внутренние функции).
3. Формы (`.dfm`) и картинка диалога лежат в той же папке, что и `.pas` (`DocumentPath` в `.PrjScr` — имя файла рядом).
4. Файл `CustomScripts.PrjScr` в корне набора — только заметка, **без** списка скриптов. Не собирайте несколько `.pas` в один проект.

Диалог открывается даже без открытого PCB/схемы; работа с платой — только по OK.

Интерфейс диалогов — светлый (Segoe UI, форма `Color = clBtnFace`). У `TButton` нет свойства Color — в `.dfm` его нет. Подписи в `.dfm` — коды `#NNNN` **без пробелов между кодами** (UTF-16), как грузит Altium. Информационные тексты: `ShowMessage` со строками Caption (скрытые `TLabel` с `#NNNN`). Да/нет: `ConfirmNoYes`. Десятичные поля разбираются вручную (`XxxParseFloat`: trim, `,`/`.` как точка, знак и цифры циклом; и `3.2`, и `3,2`). В `.dfm` у `TImage` нет `Picture.Data` — картинка грузится из файла.

Идентификаторы в коде — на английском, с префиксом скрипта (`PanR`, `FilBoard`, …), чтобы даже случайная сборка нескольких файлов не давала `redeclared`.

## Картинки в диалогах

У **каждого** скрипта всплывающее окно: слева `TImage`, справа параметры и OK/Отмена.

PNG/BMP **320×214** лежат в папке скрипта (рядом с `.PrjScr`). Запасные копии — [`images/`](images/). `TImage` в `.dfm` пустой; `LoadFromFile` если файл есть.

Иконки меню/панели: [`Shortcuts/`](Shortcuts/) (`24x24` и `32x32` BMP). **DXP → Customizing → Bitmap**.

Путь загрузки: папка **этого** `.PrjScr` / `.pas`, затем `images\`.

## Устранение сбоя «Разрушительный сбой»

- Сохраняйте `.pas` как **UTF-8 с BOM** (как сейчас в репозитории). UTF-8 без BOM с кириллицей ломает старый DelphiScript.
- Не читайте аргументы командной строки EXE (в скриптах Altium это даёт AV).
- Запускайте уникальную `Start…` / `_Start…` того проекта, который открыт (см. таблицу выше).
- Картинки не вшивать в `.dfm`. Кладите PNG/BMP в папку скрипта (или `images\`).
- В каждом `.PrjScr` только **один** `.pas` (как в примере Fillet), без PNG и без `.dfm` отдельными документами.
- Если Altium открывает `Panelizer.pas` и пишет **Identifier redeclared** — в проект попало больше одного `.pas`. Закройте общий проект и откройте нужный `*.PrjScr`.

## Скрипты

### 1. Скругления углов трека — `TrackCornerFillet.pas`

**Назначение.** Ставит скругления (fillet, `IPCB_Arc`) заданного радиуса на **выбранные углы**: в вершине должны быть выделены оба сегмента. Две стороны квадрата = **один** угол, контур сам не добирается.

**Как запускать.** Откройте `CustomScripts/TrackCornerFillet/TrackCornerFillet.PrjScr`, PCB, выделите **оба сегмента угла** (и дугу, если она уже есть), DXP → Run Script → `StartTrackCornerFillet`.

**Параметры.** Радиус в мм (по умолчанию **0,5**). Допускаются `0.5` и `0,5`. **Радиус 0** снимает скругления (треки продлеваются до угла, ошибка не выдаётся). Если на выбранных углах уже есть дуги и R>0, один раз спрашивается: «переделать?»

**Поведение.** Угол — ровно два выделенных сегмента в вершине. Повтор с новым радиусом обновляет **все выбранные** углы (снимок дуг до удаления). Слишком большой радиус — вершина пропускается.

**Ограничения.** Не скругляет стык трек–дуга, если дуга не является скруглением между двумя треками. Не работает с `IPCB_Connection` (крысы).

### 2. DXF контуров слоёв — `DxfOutlineExport.pas`

**Не закончен / заброшен.** Скрипт DXF не доведён; не использовать.

### 3. Панелизация — `Panelizer.pas`

**Назначение.** Новый `.PcbDoc`, массив исходной платы, **вырез в заготовке** вокруг каждой платы (паз шириной = диаметр фрезы = 2×радиус, разрывы = перемычки 4 мм) и **прямоугольная внешняя рамка** = габарит массива **плюс поле с каждой стороны** (по умолчанию 10 мм) на механическом слое.

**Параметры по умолчанию**

| Параметр | Значение |
| --- | --- |
| Столбцы (X) × ряды (Y) | **4 × 2** (8 плат) |
| Зазор плата–плата | **2 мм** |
| Поле до края панели | **10 мм** |
| Ширина перемычки (web) | **4 мм** |
| Радиус фрезы (смещение пути) | **1 мм** |
| Перемычки | Разрывы в пути фрезы шириной web, **без сверловки** |
| Механический слой контура | Mechanical 1 |

Массив: `IPCB_EmbeddedBoard`. Общие пазы между платами — **один** канал ширины Gap (обе стенки + dogbone). Внутренняя стенка на **углу платы** копирует дугу `BoardOutline` (Rboard). Внешняя на углах массива — концентрическая Rboard+Gap. **Отдельные T-вырезы** на стыке двух плат у края массива: ножка = общая аллея, перекладина = **внешние** кромки фрезы этих двух плат, продлённые навстречу через аллею. T **не** сливается с контуром заготовки (зазор = поле). Перемычки не трогались (2 на вертикали ¼/¾, 1 по центру горизонтали). Рамка панели — bbox+поле.

**Ограничения.** Embedded Board Array в скриптах AD не всегда копирует шелкографию панели. Сложный непрямоугольный контур исходной платы копируется ограничено.

### 4. Сброс и обновление десигнаторов схемы — `SchDesignatorReset.pas`

**Назначение.** Перенумерация **всего проекта** (все листы). Порядок Altium **Down then Across**. Скрипт **не присваивает** `DM_LogicalDesignator` / `DM_PhysicalDesignator`. Открывает каждый SCH-лист и вызывает `ResetParameters; AddStringParameter('Action','ReAnnotate'); RunProcess('Sch:Annotate')` (сброс: `RunProcess('Sch:ResetDesignators')`). Если диалог Annotation открылся — best-effort `CreateOleObject('WScript.Shell').SendKeys('{ENTER}')` (OK). Если COM недоступен или диалог остался на экране: подтвердите **Tools → Annotation** вручную (positional Down then Across, OK). ConfirmNoYes перед всем проектом.

**Параметры.** По умолчанию: перенумеровать + все листы. Опция сброса в `?` выключена, но доступна.

**Ограничения.** Скрипт не пишет десигнаторы через DM_. ECO на PCB автоматически не выполняется.

### 5. Выгрузка BOM — `BomExport.pas`

**Назначение.** BOM в **CSV UTF-16 LE** (`Write` целой уже закодированной строки: BOM `#$FF#$FE`, символы по 2 байта, CRLF `0D 00 0A 00`). Разделитель **`;`**. Каждое поле в `"..."`. **Без `BlockWrite`**. `TSaveDialog` (Отмена = выход).

**Столбцы:** `Comment;Designator;Description;Value;Quantity`. **Value = `DM_Comment`.** Кириллица (`Резистор`) — код U+0420… в UTF-16 LE, Excel не показывает `????`.

**Состав.** **Все** компоненты со **всех листов**. Чтение: `DM_ComponentCount` / `DM_Components` / `DM_Comment` / `DM_FootPrint` / `DM_LogicalDesignator` / `DM_PhysicalDesignator` (только чтение).

**Группировка.** По Value (+ Comment/Description/footprint). Designator — склейка. Рядом `*.bom.settings.xml` (`TStringList.SaveToFile`).

### 6. Земляные полигоны по контуру — `GroundPolygons.pas`

**Назначение.** Заливки (`IPCB_Polygon`) по **контуру платы** на всех сигнальных медных слоях, цепь **GND**.

**Зазоры скрипт не задаёт** — ими управляют **правила проектирования**. Поля зазора в диалоге нет.

Стиль по умолчанию — solid. Если полигон этой цепи на слое уже есть — спросить заменить/пропустить.

**Ограничения.** Внутренние plane-слои не заливаются как signal polygon. Если контура нет — bounding box. Rule Wizard не вызывается.

### 7. Мастер новой PCB — `PcbWizard.pas`

**Назначение.** Вся настройка в диалоге: размер, keep-out со скруглениями, крепёж, слои, полигоны GND, вскрытие маски, сетка.

**По умолчанию.** 80×50 мм, скругление 2 мм, **4 медных слоя**, **4 отверстия по углам**, сетка **0,1 мм**, отверстие **3,2 мм** (ввод `3.2` и `3,2`). Отступ 4 мм.

**Ограничения.** Полная перестройка layer stack (2→4→6) через скрипт в AD20+ ненадёжна — стек лучше задать шаблоном / Layer Stack Manager. «Вскрытие маски» — `IPCB_Polygon` по контуру платы **только на Bottom Solder** (не Top, не `IPCB_Fill`). Полигоны GND — копия `BoardOutline.Segments`, без `.Kind`.

### 8. Авторасстановка десигнаторов на PCB — `PlaceDesignators.pas`

**Назначение.** Только **шелкография** (Top/Bottom Overlay). Если выделены компоненты — только они; **если выделения нет — все**.

Кандидаты: 8 направлений × 5 шагов (жёсткий потолок). Площадки и чужие имена кэшируются **один раз**. Площадки `BoundingRectangle` + 0.25 мм; имя внутри `BoardOutline.PointInPolygon` (4 угла). Движение как AutoPlaceSilkscreen: `BeginModify`, `ChangeNameAutoposition := eAutoPos_Manual`, `MoveToXY`, `EndModify`, `ViewManager_FullUpdate`. Нет легальной позиции — пропуск, без зависания.

**Ограничения.** Нет courtyard — используется `BoundingRectangleNoNameComment`. При плотной шелкографии остаётся лучший кандидат с предупреждением.

### 3.1 Offset треков — `Offset.pas`

**Назначение.** CAD OFFSET. Каждая сущность цепи смещается (короткие сегменты не отбрасываются). **Острый угол:** extend/trim обоих offset-рёбер до **пересечения**. Дуга радиуса `|d|` на острых углах **не** вставляется (скругление только если исходная вершина уже была дугой). Дуги/окружности: тот же центр, R±d, **те же** StartAngle/EndAngle (не менять местами — выворот). Если внутрь R−d≤0 — пропуск + ShowMessage. Замкнутый: сторона от signed area. Открытый: наружу = слева. Префикс `Off*`.

### 3.2 Панелизация (тест фрезы) — `PanelizerTest.pas`

**Назначение.** Те же перемычки, что у Panelizer (копия `DrawSlotV`/`DrawSlotH`, без подстройки). Копия `BoardOutline` (треки+дуги). Отдельные T-вырезы на краевых стыках, как в §3 (перекладина = стык внешних кромок, не в рамку). После отрисовки — удаление совпадений и сегментов внутри паза. Префикс `PTst*`.

## Общие замечания по API

Используются только известные интерфейсы: `PCBServer`, `IPCB_Board`, `IPCB_Track`, `IPCB_Arc`, `IPCB_Pad`, `IPCB_Via`, `IPCB_Polygon`, `IPCB_Component`, `SchServer`, `ISch_Document`, `ISch_Component`, `Client` / `ResetParameters` / `RunProcess`.

Где API ненадёжен, сделан best-effort и описано ограничение — пустых заглушек нет.

## Соответствие примерам

Стиль близок к скриптам в `!SCRIPTS`: формы `.dfm`, `PCBServer.PreProcess`/`PostProcess` для Undo, `Board.SelectecObjectCount` (историческая опечатка API), `MMsToCoord` / `CoordToMMs`, `MkSet`.
