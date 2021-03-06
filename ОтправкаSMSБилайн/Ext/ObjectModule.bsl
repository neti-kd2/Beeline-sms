﻿////////////////////////////////////////////////////////////////////////////////
// ПЕРЕМЕННЫЕ МОДУЛЯ

Перем Версия Экспорт; // Версия программы, отображается в заголовке главной формы


////////////////////////////////////////////////////////////////////////////////
// ЭКСПОРТНЫЕ ПРОЦЕДУРЫ И ФУНКЦИИ

Функция ОтправитьСМС() Экспорт
	
	АдресСервиса = "beeline.amega-inform.ru";
	ШаблонМетода = "sms_send/";
	
	ПараметрыЗапроса = Новый Структура;
	ПараметрыЗапроса.Вставить("user", Логин);
	ПараметрыЗапроса.Вставить("pass", Пароль);
	ПараметрыЗапроса.Вставить("sender", ИмяОтправителя);
	ПараметрыЗапроса.Вставить("CLIENTADR", "127.0.0.1");
	ПараметрыЗапроса.Вставить("action", "post_sms");
	ПараметрыЗапроса.Вставить("target ", Получатели);
	ПараметрыЗапроса.Вставить("message", ТекстСообщения);
	
	СтрокаОтвет = "";
	СтруктураОтвета = ВыполнитьHTTPЗапрос(АдресСервиса, ШаблонМетода, "POST", ПараметрыЗапроса,,, СтрокаОтвет);
	
	Возврат СтруктураОтвета;
	
КонецФункции

Функция ВыполнитьHTTPЗапрос(Знач АдресСервиса, Знач ШаблонМетода, Знач Направление = "Get", Знач Параметры, Знач ДопПараметрыСтрокой = "", Знач ПрочитатьВСоответствие = Ложь, СтрокаОтвет = "") Экспорт
	
	// Собираем текст запроса
	СтрПараметры = "";
	
	Если ЗначениеЗаполнено(Параметры) Тогда
		Для Каждого КлючИЗначение Из Параметры Цикл
			ИмяПараметра	  = КлючИЗначение.Ключ;
			ЗначениеПараметра = Формат(КлючИЗначение.Значение, "ЧРД=.; ЧГ=");
			
			Если ЗначениеЗаполнено(ЗначениеПараметра) Тогда
				СтрПараметры = СтрПараметры + ?(СтрПараметры = "", "", "&") + ИмяПараметра + "=" + ЗначениеПараметра;
			КонецЕсли;
		КонецЦикла;
	КонецЕсли;
	
	СтрПараметры = СтрПараметры + ?(ДопПараметрыСтрокой="", "", "&" + ДопПараметрыСтрокой);
	
	//ТекстЗапроса = encodeURIComponent(ТекстЗапроса);
	Таймаут = 15;
	
	HTTPСоединение = Новый HTTPСоединение(АдресСервиса,,,,, Таймаут, Новый ЗащищенноеСоединениеOpenSSL);
	HTTPЗапрос = Новый HTTPЗапрос();
	HTTPЗапрос.Заголовки.Вставить("Content-Type", "application/x-www-form-urlencoded");
	HTTPЗапрос.Заголовки.Вставить("Accept-Encoding", "gzip");
	
	Попытка
		Если ВРЕГ(Направление) = "GET" Тогда
			СтрПараметры = ?(СтрПараметры="", "", "?" + СтрПараметры);
			ТекстЗапроса = ?(ШаблонМетода= "", "", "/") + ШаблонМетода + СтрПараметры;
			HTTPЗапрос.АдресРесурса = ТекстЗапроса;
			
			Ответ = HTTPСоединение.Получить(HTTPЗапрос);
		ИначеЕсли ВРЕГ(Направление) = "POST" Тогда
			HTTPЗапрос.УстановитьТелоИзСтроки(СтрПараметры, КодировкаТекста.UTF8, ИспользованиеByteOrderMark.НеИспользовать);
			HTTPЗапрос.АдресРесурса = ШаблонМетода;
			
			Ответ = HTTPСоединение.ОтправитьДляОбработки(HTTPЗапрос);
		Иначе
			Сообщить("Не знаю как обрабатывать направление " + Направление);
 			Возврат Неопределено
		КонецЕсли;
		
	Исключение
		Сообщить("Ошибка при выполнении запроса " + АдресСервиса + "/" + ТекстЗапроса + ". " + ОписаниеОшибки());
		Возврат Неопределено
	КонецПопытки;
	
	КодСостояния = Ответ.КодСостояния;
	Если КодСостояния <> 200 Тогда
		//СтрокаОтвет = ПереобразоватьЮникод(СтрокаОтвет);
		ТекстОшибки = "URI ресурса: " + АдресСервиса + HTTPЗапрос.АдресРесурса + Символы.ПС + "Тело: " + HTTPЗапрос.ПолучитьТелоКакСтроку() + Символы.ПС +
		"Ответ: " + СтрокаОтвет;
		
		Сообщить("Ошибка: " + ТекстОшибки, СтатусСообщения.Важное);
		
		Возврат Неопределено
	КонецЕсли;
	
	Если Ответ.Заголовки.Получить("Content-Encoding")="gzip" Тогда
		СтрокаОтвет = РасшифроватьGZIP(Ответ.ПолучитьТелоКакДвоичныеДанные());
	Иначе
		СтрокаОтвет = Ответ.ПолучитьТелоКакСтроку();
	КонецЕсли;
	//СтруктураОтвета = UnJSON(СтрокаОтвет, "Выполнение метода " + АдресСервиса + "/" + ТекстЗапроса, ПрочитатьВСоответствие);
	
	ЧтениеXML = Новый ЧтениеXML();
	ЧтениеXML.УстановитьСтроку(СтрокаОтвет);
	
	//ДокументДОМ = Новый ДокументDOM;
	//ДокументДОМ.П
	ПостроительДОМ = Новый ПостроительDOM;
	ДокументДОМ = ПостроительДОМ.Прочитать(ЧтениеXML);
	//ЧтениеXML.УстановитьСтроку(СтрокаОтвет);
	//Прочитали = ФабрикаXDTO.ПрочитатьXML(ЧтениеXML);
	
	Output = ПолучитьЭлементПоИмениDOM(ДокументДОМ.ДочерниеУзлы, "output");
	Ошибки = ПолучитьЭлементПоИмениDOM(Output.ДочерниеУзлы, "errors");
	Успешные = ПолучитьЭлементПоИмениDOM(Output.ДочерниеУзлы, "result");
	
	СтруктураОтвета = Новый Структура;
	
	Если Ошибки <> Неопределено Тогда
		//<?xml version='1.0' encoding='UTF-8'?><output><RECEIVER AGT_ID="15507" DATE_REPORT="18.05.2020 09:45:35"/><result sms_group_id="1626796222257967810676"><sms id="583055310202301260" smstype="SENDSMS" phone="+79023552448" sms_res_count="1"><![CDATA[Test!]]></sms></result></output>
		ТекстОшибок = Ошибки.ТекстовоеСодержимое;
		//ТекстОшибокДекодировано = РаскодироватьСтроку(ТекстОшибок, СпособКодированияСтроки.КодировкаURL, "UTF-8");
		
		// Хз кто так придумал в UTF-8 XML складывать Windows-1251 строку :-/ Перекодируем
		ИмяВременногоФайла = ПолучитьИмяВременногоФайла(".txt");
		Текст = Новый ТекстовыйДокумент();
		Текст.ДобавитьСтроку(ТекстОшибок);
		Текст.Записать(ИмяВременногоФайла, КодировкаТекста.ANSI);
		
		Текст.Прочитать(ИмяВременногоФайла, КодировкаТекста.UTF8);
		ТекстОшибокДекодировано = Текст.ПолучитьТекст();
		УдалитьФайлы(ИмяВременногоФайла);
		
		СтруктураОтвета.Вставить("errors", ТекстОшибокДекодировано);
	КонецЕсли;
	
	Если Успешные <> Неопределено Тогда
		// <?xml version='1.0' encoding='UTF-8'?><output><RECEIVER AGT_ID="15507" DATE_REPORT="18.05.2020 09:51:51"/><result sms_group_id="1626796223507786182784"><sms id="583055322501229754" smstype="SENDSMS" phone="+79023552448" sms_res_count="1"><![CDATA[Проверка (Postman)]]></sms></result></output>
		СтруктураОтвета.Вставить("result", Истина);
	КонецЕсли;
	
	Возврат СтруктураОтвета;
	
КонецФункции

Функция UnJSON(СтрокаJSON, ТекстОписанияОшибки="", ПрочитатьВСоответствие = Истина) Экспорт
	Попытка
		ЧтениеJSON=Новый ЧтениеJSON;
		ЧтениеJSON.УстановитьСтроку(СтрокаJSON);
		Значение=ПрочитатьJSON(ЧтениеJSON, ПрочитатьВСоответствие);
		ЧтениеJSON.Закрыть();
		Возврат Значение
	Исключение
		Сообщить(ТекстОписанияОшибки + Символы.ПС + ОписаниеОшибки(), СтатусСообщения.Важное);
		
		Если ЗначениеЗаполнено(ТекстОписанияОшибки) Тогда
			Текст = Новый ТекстовыйДокумент;
			Текст.УстановитьТекст(ТекстОписанияОшибки);
			Текст.Показать("Покажите этот отчет разработчику программы " + Метаданные().Синоним);
		КонецЕсли;
	КонецПопытки;
КонецФункции

Функция JSON(Структура) Экспорт
    ЗаписьJSON=Новый ЗаписьJSON;
    ЗаписьJSON.УстановитьСтроку();
    ЗаписатьJSON(ЗаписьJSON,Структура,Новый НастройкиСериализацииJSON,"ПреобразованиеJSON");
    Возврат ЗаписьJSON.Закрыть()
КонецФункции

Функция РасшифроватьGZIP(ДвоичныеДанные)
	// Получение сжатого тела из GZIP
	Поток = ДвоичныеДанные.ОткрытьПотокДляЧтения();
	Поток.Перейти(10, ПозицияВПотоке.Начало);
	БуферТелаФайла = Новый БуферДвоичныхДанных(Поток.Размер()-10);
	Поток.Прочитать(БуферТелаФайла,0,Поток.Размер()-18);
	// Получение CRC(Контрольного хэша файла)
	БуферCRC = Новый БуферДвоичныхДанных(4);
	Поток.Перейти(Поток.Размер()-8, ПозицияВПотоке.Начало);
	Поток.Прочитать(БуферCRC,0,4);
	CRC=БуферCRC.ПрочитатьЦелое32(0);
	// Получение размера несжатого файла
	БуферРазмерНесжатого = Новый БуферДвоичныхДанных(4);
	Поток.Перейти(Поток.Размер()-4, ПозицияВПотоке.Начало);
	Поток.Прочитать(БуферРазмерНесжатого,0,4);
	РазмерРаспакованногоФайла=БуферРазмерНесжатого.ПрочитатьЦелое32(0);
	// Сформирование валидной ZIP структуры
	Поток.Закрыть();
	ПотокВПамяти = Новый ПотокВПамяти(БуферТелаФайла);
	
	ИмяСжатогоФайла="body.json";
	ДлинаИмениСжатогоФайла		= СтрДлина(ИмяСжатогоФайла);
	РазмерСжатогоФайла			= ПотокВПамяти.Размер();
	ВремяФайла					= 0;
	ДатаФайла					= 0;
	РазмерZIP = 98+ДлинаИмениСжатогоФайла*2+РазмерСжатогоФайла; //98 Байт заголовки, 2 раза длина файла + размер сжатого тела
	БинарныйБуфер = Новый БуферДвоичныхДанных(РазмерZIP);
	//	// [Local File Header]
	ДлинаФиксированнойЧастиLFH = 30;
	
	БинарныйБуфер.ЗаписатьЦелое32(0	, 67324752);					//Обязательная сигнатура 0x04034B50
	БинарныйБуфер.ЗаписатьЦелое16(4	, 20); 							//Минимальная версия для распаковки
	БинарныйБуфер.ЗаписатьЦелое16(6	, 2050);						//Битовый флаг
	БинарныйБуфер.ЗаписатьЦелое16(8	, 8); 							//Метод сжатия (0 - без сжатия, 8 - deflate)
	БинарныйБуфер.ЗаписатьЦелое16(10, ВремяФайла); 					//Время модификации файла
	БинарныйБуфер.ЗаписатьЦелое16(12, ДатаФайла); 					//Дата модификации файла
	БинарныйБуфер.ЗаписатьЦелое32(14, CRC);							//Контрольная сумма
	БинарныйБуфер.ЗаписатьЦелое32(18, РазмерСжатогоФайла);			//Сжатый размер
	БинарныйБуфер.ЗаписатьЦелое32(22, РазмерРаспакованногоФайла);	//Несжатый размер
	БинарныйБуфер.ЗаписатьЦелое16(26, ДлинаИмениСжатогоФайла);		//Длина название файла
	БинарныйБуфер.ЗаписатьЦелое16(28, 0);							//Длина поля с дополнительными данными
	
	//Название файла
	Для й = 0 По ДлинаИмениСжатогоФайла - 1 Цикл
		БинарныйБуфер.Установить(ДлинаФиксированнойЧастиLFH + й, КодСимвола(Сред(ИмяСжатогоФайла, й + 1, 1)));
	КонецЦикла;
	
	// [Сжатые данные]
	БуферСжатыхДанных = Новый БуферДвоичныхДанных(РазмерСжатогоФайла);
	
	ПотокВПамяти.Прочитать(БуферСжатыхДанных, 0, РазмерСжатогоФайла);
	ПотокВПамяти.Закрыть();
	
	БинарныйБуфер.Записать(ДлинаФиксированнойЧастиLFH + ДлинаИмениСжатогоФайла, БуферСжатыхДанных);
	
	ТекущееСмещение = ДлинаФиксированнойЧастиLFH + ДлинаИмениСжатогоФайла + РазмерСжатогоФайла;
	
	// [Central directory file header]
	ДлинаФиксированнойЧастиCDFH	= 46;
	ДлинаДополнительныхДанных	= 0;
	
	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + 0	, 33639248);					//Обязательная сигнатура 0x02014B50
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 4	, 814); 						//Версия для создания
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 6	, 20); 							//Минимальная версия для распаковки
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 8	, 2050);						//Битовый флаг
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 10	, 8); 							//Метод сжатия (0 - без сжатия, 8 - deflate)
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 12	, ВремяФайла); 					//Время модификации файла
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 14	, ДатаФайла); 					//Дата модификации файла
	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + 16	, CRC);							//Контрольная сумма
	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + 20	, РазмерСжатогоФайла);			//Сжатый размер
	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + 24	, РазмерРаспакованногоФайла);	//Несжатый размер
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 28	, ДлинаИмениСжатогоФайла);		//Длина название файла
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 30	, ДлинаДополнительныхДанных);	//Длина поля с дополнительными данными
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 32	, 0);							//Длина комментариев к файлу
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 34	, 0);							//Номер диска
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 36	, 0);							//Внутренние аттрибуты файла
	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + 38	, 2176057344);					//Внешние аттрибуты файла
	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + 42	, 0);							//Смещение до структуры LocalFileHeader
	
	//Название файла
	Для й = 0 По ДлинаИмениСжатогоФайла - 1 Цикл
		БинарныйБуфер.Установить(ТекущееСмещение + ДлинаФиксированнойЧастиCDFH + й, КодСимвола(Сред(ИмяСжатогоФайла, й + 1, 1)));
	КонецЦикла;
	
	ТекущееСмещение = ТекущееСмещение + ДлинаФиксированнойЧастиCDFH + ДлинаИмениСжатогоФайла;
	
	//Дополнительные данные отсутствуют
	
	//Данные комментария отсутствуют
	
	ТекущееСмещение = ТекущееСмещение + ДлинаДополнительныхДанных;
	
	// [End of central directory record (EOCD)]
	РазмерCentralDirectory		= ДлинаФиксированнойЧастиCDFH + ДлинаИмениСжатогоФайла + ДлинаДополнительныхДанных;
	СмещениеCentralDirectory	= ДлинаФиксированнойЧастиLFH  + ДлинаИмениСжатогоФайла + РазмерСжатогоФайла;
	
	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + 0	, 101010256);					//Обязательная сигнатура 0x06054B50
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 4	, 0); 							//Номер диска
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 6	, 0); 							//Номер диска, где находится начало Central Directory
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 8	, 1); 							//Количество записей в Central Directory в текущем диске
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 10	, 1); 							//Всего записей в Central Directory
	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + 12	, РазмерCentralDirectory);		//Размер Central Directory
	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + 16	, СмещениеCentralDirectory);	//Смещение Central Directory
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 20	, 0);							//Длина комментария
	
	//Данные комментария отсутствуют
	РазделительПутей=ПолучитьРазделительПути();
	КаталогВременныхФайлов=КаталогВременныхФайлов()+РазделительПутей+"GZIP";
	
	ПотокВПамяти = Новый ПотокВПамяти(БинарныйБуфер);
	Файл = Новый ЧтениеZipФайла(ПотокВПамяти);
	Файл.Извлечь(Файл.Элементы[0], КаталогВременныхФайлов,РежимВосстановленияПутейФайловZIP.НеВосстанавливать);
	ПотокВПамяти.Закрыть();
	//Чтение текста
	ЧтениеТекста=Новый ЧтениеТекста(КаталогВременныхФайлов+РазделительПутей+"body.json");
	Текст=ЧтениеТекста.Прочитать();
	ЧтениеТекста.Закрыть();
	УдалитьФайлы(КаталогВременныхФайлов);
	Возврат Текст;	
КонецФункции	


////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ И ФУНКЦИИ ОБЩЕГО НАЗНАЧЕНИЯ

Функция ПереобразоватьЮникод(Строка)

    
    ГотововаяСтрока = "" ;
    
    МасУкр = Новый Массив(66) ;
    
    МасУкр[0]="А";   МасУкр[1]="Б";  МасУкр[2]="В";  МасУкр[3]="Г";  МасУкр[4]="Ґ";  МасУкр[5]="Д";
    МасУкр[6]="Е";   МасУкр[7]="Є";  МасУкр[8]="Ж";  МасУкр[9]="З";  МасУкр[10]="И"; МасУкр[11]="І";
    МасУкр[12]="Ї";  МасУкр[13]="Й"; МасУкр[14]="К"; МасУкр[15]="Л"; МасУкр[16]="М"; МасУкр[17]="Н";
    МасУкр[18]="О";  МасУкр[19]="П"; МасУкр[20]="Р"; МасУкр[21]="С"; МасУкр[22]="Т"; МасУкр[23]="У";
    МасУкр[24]="Ф";  МасУкр[25]="Х"; МасУкр[26]="Ц"; МасУкр[27]="Ч"; МасУкр[28]="Ш"; МасУкр[29]="Щ";
    МасУкр[30]="Ь";  МасУкр[31]="Ю"; МасУкр[32]="Я";  

    МасУкр[33]="а";  МасУкр[34]="б"; МасУкр[35]="в"; МасУкр[36]="г"; МасУкр[37]="ґ"; МасУкр[38]="д";
    МасУкр[39]="е";  МасУкр[40]="є"; МасУкр[41]="ж"; МасУкр[42]="з"; МасУкр[43]="и"; МасУкр[44]="і";
    МасУкр[45]="ї";  МасУкр[46]="й"; МасУкр[47]="к"; МасУкр[48]="л"; МасУкр[49]="м"; МасУкр[50]="н";
    МасУкр[51]="о";  МасУкр[52]="п"; МасУкр[53]="р"; МасУкр[54]="с"; МасУкр[55]="т"; МасУкр[56]="у";
    МасУкр[57]="ф";  МасУкр[58]="х"; МасУкр[59]="ц"; МасУкр[60]="ч"; МасУкр[61]="ш"; МасУкр[62]="щ";
    МасУкр[63]="ь";  МасУкр[31]="ю"; МасУкр[65]="я";  
        
    
    МасКод = Новый Массив(66) ;
    
    МасКод[0]="0410";   МасКод[1]="0411";  МасКод[2]="0412";  МасКод[3]="0413";  МасКод[4]="0490";  МасКод[5]="0414";
    МасКод[6]="0415";   МасКод[7]="0404";  МасКод[8]="0416";  МасКод[9]="0417";  МасКод[10]="0418"; МасКод[11]="0406";
    МасКод[12]="0407";  МасКод[13]="0419"; МасКод[14]="041A"; МасКод[15]="041B"; МасКод[16]="041C"; МасКод[17]="041D";
    МасКод[18]="041E";  МасКод[19]="041F"; МасКод[20]="0420"; МасКод[21]="0421"; МасКод[22]="0422"; МасКод[23]="0423";
    МасКод[24]="0424";  МасКод[25]="0425"; МасКод[26]="0426"; МасКод[27]="0427"; МасКод[28]="0428"; МасКод[29]="0429";
    МасКод[30]="042C";  МасКод[31]="042E"; МасКод[32]="042F";  

    МасКод[33]="0430";  МасКод[34]="0431"; МасКод[35]="0432"; МасКод[36]="0413"; МасКод[37]="0491"; МасКод[38]="0434";
    МасКод[39]="0435";  МасКод[40]="0454"; МасКод[41]="0436"; МасКод[42]="0437"; МасКод[43]="0438"; МасКод[44]="0456";
    МасКод[45]="0457";  МасКод[46]="0439"; МасКод[47]="043A"; МасКод[48]="043B"; МасКод[49]="043C"; МасКод[50]="043D";
    МасКод[51]="043E";  МасКод[52]="043F"; МасКод[53]="0440"; МасКод[54]="0441"; МасКод[55]="0442"; МасКод[56]="0443";
    МасКод[57]="0444";  МасКод[58]="0445"; МасКод[59]="0446"; МасКод[60]="0447"; МасКод[61]="0448"; МасКод[62]="0449";
    МасКод[63]="044C";  МасКод[31]="044E"; МасКод[65]="044F";  
    
    
    тмпСтрока = "" ;
    Для Счетчик = 1 По СтрДлина(Строка) Цикл      
        Если Лев(Строка, 1) = "\" Тогда
            Если Лев(Строка, 2) = "\u" Тогда
                
                тмпСтрока = Прав(Лев(Строка, 6),4) ;
                Если МасКод.Найти(тмпСтрока) = Неопределено Тогда
                    СтрокаЗамены = Прав(тмпСтрока, 1) ;
                    тмпСтрока = СтрЗаменить(тмпСтрока,СтрокаЗамены,ТРег(СтрокаЗамены)); 
                    Если МасКод.Найти(тмпСтрока) = Неопределено Тогда
                        Сообщить("Код символа не найден: " + тмпСтрока) ;
                    Иначе                      
                        ГотововаяСтрока = ГотововаяСтрока + МасУкр[МасКод.Найти(тмпСтрока)] ;                                   
                    КонецЕсли;
                Иначе
                    ГотововаяСтрока = ГотововаяСтрока + МасУкр[МасКод.Найти(тмпСтрока)] ;               
                КонецЕсли;
                
                Строка = Прав(Строка, (СтрДлина(Строка)-6)) ; 
            Иначе  
                Строка = Прав(Строка, (СтрДлина(Строка)-2)) ;
            КонецЕсли;
        Иначе
            ГотововаяСтрока = ГотововаяСтрока + Лев(Строка, 1) ;
            Строка = Прав(Строка, (СтрДлина(Строка)-1)) ;     
        КонецЕсли;         
    КонецЦикла;   

    Возврат ГотововаяСтрока ;
        
КонецФункции

Функция encodeURIComponent(Знач URL)
	// Заменим "+" на "%2B", типа encodeURIComponent()
	URL = СтрЗаменить(URL, "+", "%2B");
	URL = КодироватьСтроку(URL, СпособКодированияСтроки.URLВКодировкеURL);
	
	Возврат URL
КонецФункции

#Область ФункцииРаботыDOM

&НаКлиенте
Функция ПолучитьЭлементПоИмениDOM(КоллекцияЭлементов, ИмяЭлемента)
	
	Для Каждого ЭлементDOM Из КоллекцияЭлементов Цикл
		Если  ЭлементDOM.ИмяУзла = ИмяЭлемента Тогда
			Возврат ЭлементDOM;
		КонецЕсли;
	КонецЦикла;
	
КонецФункции

&НаКлиенте
Функция ПолучитьЗначениеАтрибута(ЭлементDOM, ИмяАтрибута = "name")
	
	АтрибутName = ПолучитьЭлементПоИмениDOM(ЭлементDOM.Атрибуты, "name");
	
	Если АтрибутName <> Неопределено Тогда
		Возврат АтрибутName.Значение;
	КонецЕсли;
	
КонецФункции

// Функция возвращает список атрибутов элемента DOM
//
// Параметры:
//  ЭлементDOM  - ЭлементDOM - Элемент DOM атрибуты которого необходимо получить
//
// Возвращаемое значение:
//   СписокЗначений
//		Значение	  - значение атрибута
//		Представление - имя атрибута
//
&НаКлиенте
Функция ПолучитьСписокАтрибутов(ЭлементDOM)
	
	СписокАтрибутов = Новый СписокЗначений;
	
	// СП: Коллекция атрибутов доступна только для узла Element.
	Если ЭлементDOM.ТипУзла <> ТипУзлаDOM.Элемент Тогда
		Возврат СписокАтрибутов
	КонецЕсли;
	
	КоллекцияЭлементов = ЭлементDOM.Атрибуты;
	
	Для Каждого ЭлементDOM Из КоллекцияЭлементов Цикл
		СписокАтрибутов.Добавить(ЭлементDOM.Значение, ЭлементDOM.ИмяУзла);
	КонецЦикла;
	
	Возврат СписокАтрибутов
	
КонецФункции

#КонецОбласти


////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ И ФУНКЦИИ ОБЩЕГО НАЗНАЧЕНИЯ

///////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ОБРАБОТЧИКИ СОБЫТИЙ

////////////////////////////////////////////////////////////////////////////////
// ОПЕРАТОРЫ ОСНОВНОЙ ПРОГРАММЫ

Версия = "2020.05.18";


