# CustomScripts — скрипты Altium Designer 20+

Набор скриптов DelphiScript для повседневных задач PCB/схемы. Примеры в репозитории (`!SCRIPTS`) не изменялись.

Параметры согласованы с заказчиком (см. [`QUESTIONS.md`](QUESTIONS.md) — вопросы закрыты).

## Установка

У каждого скрипта **своя папка** и **свой** `.PrjScr` с **одним** `.pas` (как в `!SCRIPTS/Fillet/Fillet.PrjScr`). Altium компилирует **все** `.pas` из проекта в **одно** пространство имён: общий `CustomScripts.PrjScr` со всеми модулями даёт `Identifier redeclared`.

Открывайте `CustomScripts/<Name>/<Name>.PrjScr`.

| Скрипт | Проект | Процедура Run Script |
| --- | --- | --- |
| Скругления трека | `CustomScripts/TrackCornerFillet/TrackCornerFillet.PrjScr` | `StartTrackCornerFillet` (`_StartTrackCornerFillet`) |
| Архив проекта | `CustomScripts/ProjectZipper/ProjectZipper.PrjScr` | `StartProjectZipper` (`_StartProjectZipper`) |
| Переименование проекта | `CustomScripts/ProjectRenamer/ProjectRenamer.PrjScr` | `StartProjectRenamer` (`_StartProjectRenamer`) |
| Панелизация (прямоугольник) | `CustomScripts/Panelizer/Panelizer.PrjScr` | `StartPanelizer` |
| Панелизация (произвольный контур) | `CustomScripts/Panelize_Hard_Form/Panelize_Hard_Form.PrjScr` | `StartPanelizeHardForm` |
| Десигнаторы схемы | `CustomScripts/SchDesignatorReset/SchDesignatorReset.PrjScr` | `StartSchDesignatorReset` |
| BOM Excel | `CustomScripts/BomExport/BomExport.PrjScr` | `StartBomExport` |
| Полигоны GND | `CustomScripts/GroundPolygons/GroundPolygons.PrjScr` | `StartGroundPolygons` |
| Мастер PCB | `CustomScripts/PcbWizard/PcbWizard.PrjScr` | `StartPcbWizard` |
| Десигнаторы на PCB (вариант 1) | `CustomScripts/PlaceDesignators/PlaceDesignators.PrjScr` | `StartPlaceDesignators` |
| Десигнаторы AutoPlacer (вариант 2) | `CustomScripts/PlaceDesignators_AutoPlacer/PlaceDesignators_AutoPlacer.PrjScr` | `StartPlaceDesignatorsAuto` |
| Offset треков | `CustomScripts/Offset/Offset.PrjScr` | `StartOffset` |

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

### 2. Архив проекта — `ProjectZipper.pas`

**Назначение.** Упаковать **весь текущий проект** Altium (файл `.PrjPcb` и документы/папки рядом) в zip. Папка **`OLD`** создаётся в корне проекта (рядом с `.PrjPcb`). Zip пишется **внутрь `OLD`**: `ProjectName_YYYYMMDD_HHNN.zip`. Содержимое `OLD` в архив не входит (чтобы не зациклить предыдущие zip).

**API** — как в `Zipper-example.pas` (не OLE, не `BlockWrite`): `Zip : TXceedZip`; `Zip := TXCeedZip.Create(ZipFileName)`; `Zip.UseTempFile := False`; `Zip.BasePath := RemoveSlash(ProjectPath, cPathSeparator)`; `Zip.ProcessSubfolders := False`; `GetAllFilePathsMatchingMask(GeneratedFiles, ProjectPath, '*.*', True)`; `ExtractRelativePath`; пропуск `cFilename_CurrentDir` / `cFilename_ParentDir`; `Zip.AddFilesToProcess(Rel)`; `I := Zip.Zip`; `Zip.InstanceSize`; `Zip.Free`. Путь проекта: `GetWorkspace.DM_FocusedProject.DM_ProjectFullPath`.

**Как запускать.** Откройте `CustomScripts/ProjectZipper/ProjectZipper.PrjScr`, DXP → Run Script → `StartProjectZipper`. Диалог: папка проекта и путь zip, кнопки **Обзор…** (`SelectDirectory`, иначе `TOpenDialog` как у Panelizer). Перед `Zip.Zip` — предупреждение, что Altium **замрёт до конца архивации** (`ConfirmNoYes`), подпись «Архивация…» и `TProgressBar` (у TXceedZip нет OnProgress в Zipper-example). Форма не закрывается до конца zip (`Update`/`Refresh`). Результат — `ShowMessage` с путём.

**Ограничения.** Нужен сфокусированный проект. Префикс `Zip*`.

### 2.1 Переименование проекта — `ProjectRenamer.pas`

**Назначение.** Переименовать **файл проекта** и все `DM_LogicalDocuments` на диске. Сначала архив **ProjectZipper** — скрипт сохраняет/закрывает проект, затем `RenameFile`. History / Gerbers / `OLD\` не трогает. Символы листов в `.SchDoc` **не** правит.

**Режимы** (радиокнопки)

- **Увеличить суффикс vN / VN** (по умолчанию). Хвост stem: буква `v` или `V` (как в имени) + целое. `Widget_v2` → `Widget_v3`, `Board_V10` → `Board_V11`. Нет такого хвоста — `ShowMessage`, не переименовывать (нужна полная замена). В диалоге предпросмотр Old → New.
- **Полная замена имени.** Пользователь вводит новый stem целиком.

**Имена документов** (оба режима)

- Листы схемы в порядке `DM_LogicalDocuments`: `{NewStem}_ShN.SchDoc` (N с 1, реальное расширение).
- Одна плата: `{NewStem}.PcbDoc`; несколько: `{NewStem}_PcbN.PcbDoc`.
- Прочие: `{NewStem}` + краткий тип (OutJob / SchLib / …), чтобы имена не совпали.
- Файл проекта: `{NewStem}` + исходное расширение `.PrjPcb` / `.PrjSch` / `.PrjScr`.

**Пути в .PrjPcb.** После `RenameFile` документов файл проекта читается как текст, заменяются **имена успешно переименованных файлов**, затем сам `.PrjPcb` переименовывается. `.OutJob` из проекта — тоже. `.SchDoc` не патчится.

**После успеха.** `WorkspaceManager:SaveObject`, закрытие, rename, `DM_OpenProject` / `Client.OpenDocument` / `ObjectKind=Project`. Префикс `Ren*`.

### 3. Панелизация — `Panelizer.pas`

**Назначение.** Новый `.PcbDoc`, массив исходной платы, **вырез в заготовке** вокруг каждой платы (паз шириной = диаметр фрезы = 2×радиус, разрывы = перемычки 4 мм) и **прямоугольная внешняя рамка** = габарит массива **плюс поле с каждой стороны** (по умолчанию 10 мм) на механическом слое.

**Параметры по умолчанию**

| Параметр | Значение |
| --- | --- |
| Столбцы (X) × ряды (Y) | **4 × 2** (8 плат) |
| Зазор плата–плата | **2 мм** |
| Поле до края панели | **10 мм** |
| Ширина перемычки (web) | **4 мм** |
| Перемычки гориз. (верх/низ) | **1** на плату |
| Перемычки верт. (лево/право) | **2** на плату (¼ и ¾ при N=2) |
| Радиус фрезы (смещение пути) | **2 мм** |
| Перемычки | Разрывы в пути фрезы шириной web, **без сверловки** |
| Механический слой контура | Mechanical 3 |

Массив: `IPCB_EmbeddedBoard`. Общие пазы между платами — **один** канал ширины Gap (обе стенки + dogbone). Внутренняя стенка на **углу платы** копирует дугу `BoardOutline` (Rboard). Внешняя на углах массива — концентрическая Rboard+Gap. **Отдельные T-вырезы** на стыке двух плат у края массива: ножка = общая аллея, перекладина = **внешние** кромки фрезы этих двух плат, продлённые навстречу через аллею. T **не** сливается с контуром заготовки (зазор = поле). Число перемычек — из диалога (N равномерно по ребру, шея = TabW, inward dogbones). Рамка панели — bbox+поле; `BoardOutline` панели берётся из этой рамки (`BOARDOUTLINE_FROM_SEL_PRIMS`). Реперные знаки: 2 SMD-пада Ø1.5 мм (Top, hole 0, маска открыта) на диагонали рамки (SW и NE), отступ Margin/2, сетка 1 мм. После работы: единицы мм, сетка 0.1 мм.

**Ограничения.** Embedded Board Array в скриптах AD не всегда копирует шелкографию панели. Скрипт рассчитан на **прямоугольную** плату ( mill по bbox + дуги углов). Произвольный контур — `Panelize_Hard_Form`.

### 4. Сброс и обновление десигнаторов схемы — `SchDesignatorReset.pas`

**Назначение.** Перенумерация **всего проекта** (все листы). Порядок Altium **Down then Across**. Скрипт **не присваивает** `DM_LogicalDesignator` / `DM_PhysicalDesignator`. Открывает каждый SCH-лист и вызывает `ResetParameters; AddStringParameter('Action','ReAnnotate'); RunProcess('Sch:Annotate')` (сброс: `RunProcess('Sch:ResetDesignators')`). Без OLE / `CreateOleObject` / SendKeys. Если диалог Annotation остался на экране: подтвердите **Tools → Annotation** вручную (positional Down then Across, OK). ConfirmNoYes перед всем проектом.

**Параметры.** По умолчанию: перенумеровать + все листы. Опция сброса в `?` выключена, но доступна.

**Ограничения.** Скрипт не пишет десигнаторы через DM_. ECO на PCB автоматически не выполняется.

### 5. Выгрузка BOM — `BomExport.pas`

**Назначение.** BOM как настоящий **OOXML `*.xlsx`** (zip STORE без сжатия: `[Content_Types].xml`, `xl/workbook.xml`, `xl/worksheets/sheet1.xml`, `xl/sharedStrings.xml`, `_rels/.rels`, `xl/_rels/workbook.xml.rels`). Запись: `AssignFile` / `Rewrite(F, 1)` / `BlockWrite(F, S[i], N)` кусками 4 КБ от первого символа. `TSaveDialog` `*.xlsx` (Отмена = выход). sharedStrings и sheet в **UTF-8**: байтовая карта CP1251 `0xC0–0xFF` → UTF-8 D0/D1 (чтобы Excel показал «Резистор» и Value `10k`). Колонки шириной 28, `wrapText`.

**Столбцы** (как в `BOM_UniBrain.xlsx`): `Comment`, `Description`, `Designator`, `Value`, `Quantity`.

**Value.** Не `DM_Value` / `DM_PhysicalValue`. Цикл `DM_ParameterCount` / `DM_Parameters(i)`: `DM_Name`, затем `DM_Text`, `DM_CalculatedValue`, `DM_Data`, `GetState_Text`, `.Text`. Имена: `Value`, `Value2`, `PartValue`, `Nominal`. Если параметр Value есть, но пустой — **не** копировать Comment. Comment как номинал (`10k`, `100nF`) — только запасной разбор, если параметра нет.

**Группировка.** Value + Comment (плюс Description/footprint). Разные номиналы — разные строки. Рядом `*.bom.settings.xml`.

### 6. Земляные полигоны по контуру — `GroundPolygons.pas`

**Назначение.** Заливки (`IPCB_Polygon`) по **контуру платы** на всех сигнальных медных слоях, цепь **GND**.

**Зазоры скрипт не задаёт** — ими управляют **правила проектирования**. Поля зазора в диалоге нет.

Стиль по умолчанию — solid. Если полигон этой цепи на слое уже есть — спросить заменить/пропустить.

**Ограничения.** Внутренние plane-слои не заливаются как signal polygon. Если контура нет — bounding box. Rule Wizard не вызывается.

### 7. Мастер новой PCB — `PcbWizard.pas`

**Назначение.** Вся настройка в диалоге: размер, keep-out со скруглениями, крепёж, слои, полигоны GND, вскрытие маски, сетка.

**По умолчанию.** 80×50 мм, скругление 2 мм, **4 медных слоя**, **4 отверстия по углам**, сетка **0,1 мм**, отверстие **3,2 мм** (ввод `3.2` и `3,2`). Отступ 4 мм.

**Ограничения.** Полная перестройка layer stack (2→4→6) через скрипт в AD20+ ненадёжна — стек лучше задать шаблоном / Layer Stack Manager. «Вскрытие маски» — `IPCB_Polygon` по контуру платы **только на Bottom Solder** (не Top, не `IPCB_Fill`). Полигоны GND — копия `BoardOutline.Segments`, без `.Kind`.

### 8. Авторасстановка десигнаторов на PCB

**Вариант 1 — наша расстановка** — `PlaceDesignators.pas`, `StartPlaceDesignators`. Кандидаты сверху/снизу/слева/справа от courtyard, оценка коллизий, `MoveToXY`. Светлая форма CustomScripts.

**Вариант 2 — Silkscreen Auto Placer** — `PlaceDesignators_AutoPlacer.pas`, `StartPlaceDesignatorsAuto`. Логика **как есть** из `SilkscreenAutoPlacer/AutoPlaceSilkscreen.pas` (итераторы, коллизии, Autoposition). Русский `.dfm`. После размещения: мм, сетка 0,1 мм. Алгоритмы **не смешаны** в одном файле.

### 3.1 Offset треков — `Offset.pas`

**Пропуск правок.** Скрипт Offset в этой итерации не менялся.

**Назначение.** CAD OFFSET: выбранные треки/дуги → цепи. Snap **0.05 мм или 1 coord**. Концы дуг — `StartX`/`EndX` (не Cos/Sin углов: из-за округления одна сторона скруглённого квадрата не стыковалась и оставалась на месте). Цепь, которая не состыковалась, всё равно offset’ится (новая цепь / singleton). После join **не удаляется** offset полной стороны; если у выбранного объекта нет пары — singleton. Окружность 360° — своя цепь. Замкнутый: signed area, CCW → интерьер слева. Трек: параллель на d. Дуга: **тот же центр**, R±d, те же углы (не инвертировать). Стык в пересечении; острые углы без новых галтелей. Скруглённый прямоугольник (4 трека + 4 дуги) → 8 offset-примитивов. Префикс `Off*`.

### 3.2 Панелизация произвольного контура — `Panelize_Hard_Form.pas`

**Назначение.** Как Hard_Form: массив **встроенных плат**. Mill строится как **одна замкнутая цепь** `BoardOutline` (порядок контура), затем CAD-offset всей цепи (концентрические дуги, стык трека к `StartX`/`EndX`, не Cos/Sin, без хорд вместо дуг). Копии циклов по массиву с зазором; в общей аллее остаётся **одна** пара стенок. Перемычки — inward dogbones только на **длинных прямых** рёбрах (счётчики H/V как у Panelizer). T-карманы: внешние стенки соседей **друг к другу**, не в рамку. После offset удаляются висячие обрывки. Рамка / реперы / сетка 0.1 мм / mech 3 / R=2 мм — как раньше. Префикс `PHF*`, старт `StartPanelizeHardForm`.

**Panelizer** — прямоугольные платы. **Panelize_Hard_Form** — произвольный контур (уши, вырезы, галтели).

## Общие замечания по API

Используются только известные интерфейсы: `PCBServer`, `IPCB_Board`, `IPCB_Track`, `IPCB_Arc`, `IPCB_Pad`, `IPCB_Via`, `IPCB_Polygon`, `IPCB_Component`, `SchServer`, `ISch_Document`, `ISch_Component`, `Client` / `ResetParameters` / `RunProcess`.

Где API ненадёжен, сделан best-effort и описано ограничение — пустых заглушек нет.

## Соответствие примерам

Стиль близок к скриптам в `!SCRIPTS`: формы `.dfm`, `PCBServer.PreProcess`/`PostProcess` для Undo, `Board.SelectecObjectCount` (историческая опечатка API), `MMsToCoord` / `CoordToMMs`, `MkSet`.
