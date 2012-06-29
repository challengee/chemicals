## 0.1.2

* Template option `:symbolize_keys` that allows hash keys to string or symbols. Default to `true`.

## 0.1.1

* Performance improvement: Don't parse the source again if it is already a Nokogiri document (Parser).

## 0.1.0

* Entirely removed Hashie dependency. All keys are now symbolized in the Parser (bonus: smaller memory footprint).
