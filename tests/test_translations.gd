extends RefCounted

## Every UI string key resolves to German text. Add a language as a new
## column in i18n/strings.csv; this suite then also guards against missing
## cells via the fallback.

const CSV_PATH := "res://i18n/strings.csv"


func run(t: TestCase) -> void:
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	t.test("strings.csv opens")
	t.ok(file != null, CSV_PATH)
	if file == null:
		return
	var header := file.get_csv_line()
	t.test("German column exists")
	t.ok(header.has("de"), str(header))

	var languages: Array[String] = []
	for column in header.slice(1):
		languages.append(column)
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 2 or row[0].is_empty():
			continue
		var key := row[0]
		for i in languages.size():
			t.test("%s has text in '%s'" % [key, languages[i]])
			t.ok(row.size() > i + 1 and not row[i + 1].strip_edges().is_empty())
		t.test("%s is translated at runtime" % key)
		TranslationServer.set_locale("de")
		t.ne(TranslationServer.translate(key), StringName(key))
