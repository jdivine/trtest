from src import api
from src.api import Scope


def test_json_loading() -> None:
    definition = api.load_definition('{"term":"electric cooperative","definition":"\\"electric cooperative\\" means any cooperative association eligible to receive loans under section 904 of title 7;","scope":{"jx": "U.S.C.", "title": "16", "chapter": "47"}}')
    assert definition.term == "electric cooperative"
    assert definition.definition == "\"electric cooperative\" means any cooperative association eligible to receive loans under section 904 of title 7;"
    assert definition.scope == Scope(jx="U.S.C.", title="16", chapter="47")
