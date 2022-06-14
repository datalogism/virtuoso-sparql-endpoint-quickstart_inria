#!/usr/bin/env bash
. ../virtuoso_fct.sh --source-only

limit=500000;
echo "============ multilingual_labels.sh"
################### SPARQL - GET LANG LIST
resp=$(run_virtuoso_cmd "SPARQL \
SELECT DISTINCT CONCAT('lang_',?lang) FROM <http://fr.dbpedia.org/graph/dbpedia_generic_labels> where {\
?s rdfs:label ?o.\
BIND (lang(?o) AS ?lang)\
};";);
echo $resp;
lang_list=$(echo $resp | tr " " "\n" | grep -oP "lang_\K(.*)");

for lang in ${lang_list[@]}; do
    if [[ $lang != 'fr' ]]; then
	  echo "$lang need to be treaten";
	  
          ################### SPARQL - COUNT LANG TO DO
	  resp_todo=$(run_virtuoso_cmd "SPARQL SELECT DISTINCT COUNT(?s_lang) FROM <http://fr.dbpedia.org/graph/dbpedia_generic_labels>  WHERE {\
	  ?s_lang rdfs:label ?o_lang.\
	  FILTER(lang(?o_lang)='$lang').\
	  {\
	  SELECT ?s_fr ?s_lang FROM <http://fr.dbpedia.org/graph/dbpedia_generic_interlanguage-links> WHERE { ?s_fr owl:sameAs ?s_lang }\
	  }\
	  } ;");
	  nb_wikilinks=$(echo $resp_todo | awk '{print $4}');
	  while [ $nb_wikilinks -ne 0 ]
	  do
	  
            ################### SPARQL - ATTACH TRANSLATION TO FRENCH LABEL
	     resp_labels=$(run_virtuoso_cmd "SPARQL\
		    DEFINE sql:log-enable 2  WITH  <http://fr.dbpedia.org/graph/dbpedia_generic_labels>\
		    DELETE { ?s_lang rdfs:label ?o_lang. }\
		    INSERT { ?s_fr rdfs:label ?o_lang. }\
		    WHERE {  \
	      SELECT ?s_fr ?o_lang ?s_lang FROM <http://fr.dbpedia.org/graph/dbpedia_generic_labels>  WHERE {\
	      ?s_lang rdfs:label ?o_lang.\
	      FILTER(lang(?o_lang)='$lang').\
	      {\
		SELECT ?s_fr ?s_lang FROM <http://fr.dbpedia.org/graph/dbpedia_generic_interlanguage-links> WHERE { ?s_fr owl:sameAs ?s_lang }\
	      }\
	      }  LIMIT $limit };"); 

              ################### SPARQL - COUNT AGAIN HOW MANY WE NEED TO DO
	      resp_todo=$(run_virtuoso_cmd "SPARQL SELECT DISTINCT COUNT(?s_lang) FROM <http://fr.dbpedia.org/graph/dbpedia_generic_labels>  WHERE {\
	      ?s_lang rdfs:label ?o_lang.\
	      FILTER(lang(?o_lang)='$lang').\
	      {\
	      SELECT ?s_fr ?s_lang FROM <http://fr.dbpedia.org/graph/dbpedia_generic_interlanguage-links> WHERE { ?s_fr owl:sameAs ?s_lang }\
	      }\
	      } ;");
	      nb_wikilinks=$(echo $resp_todo | awk '{print $4}');
	      echo $nb_wikilinks;
	  done
    fi
done

 ################### SPARQL - HOW MANY WE NEED TO DELETE ?
resp2=$(run_virtuoso_cmd "SPARQL\
DEFINE sql:log-enable 2\
SELECT COUNT(distinct ?s) FROM <http://fr.dbpedia.org/graph/dbpedia_generic_labels>  where {
?s ?p ?o.
FILTER(!STRSTARTS(STR(?s), 'http://fr.dbpedia.org/') )
};");
nb_to_delete=$(echo $resp2 | awk '{print $4}');
while [ $nb_to_delete -ne 0 ]
do
	
 	################### SPARQL - DELETE LABELS THAT IS NOT RELATED TO FRENCH ENTITY
        resp2=$(run_virtuoso_cmd "SPARQL\
	DEFINE sql:log-enable 2  WITH  <http://fr.dbpedia.org/graph/dbpedia_generic_labels>\
	DELETE { ?s ?p ?o. }\
	SELECT ?s ?p ?o FROM <http://fr.dbpedia.org/graph/dbpedia_generic_labels>  where {
	?s ?p ?o.
	FILTER(!STRSTARTS(STR(?s), 'http://fr.dbpedia.org/') )
	};");
	
 	################### SPARQL - HOW MANY WE NEED TO DELETE ?
	resp2=$(run_virtuoso_cmd "SPARQL\
	DEFINE sql:log-enable 2\
	SELECT COUNT(distinct ?s) FROM <http://fr.dbpedia.org/graph/dbpedia_generic_labels>  where {
	?s ?p ?o.
	FILTER(!STRSTARTS(STR(?s), 'http://fr.dbpedia.org/') )
	};");
	nb_to_delete=$(echo $resp2 | awk '{print $4}');
done