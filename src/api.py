from pathlib import Path

import uvicorn
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel


class Scope(BaseModel):
    jx: str
    title: str
    chapter: str


class Definition(BaseModel):
    term: str
    definition: str
    scope: Scope


class TermList(BaseModel):
    terms: list[str]


def load_definition(json_str: str) -> Definition:
    return Definition.model_validate_json(json_str)


def load_definitions(path: Path) -> list[Definition]:
    acc: list[Definition] = list()
    with open(path, 'r') as f:
        for line in f:
            term = load_definition(line)
            acc.append(term)
    return acc


definitions = load_definitions(Path(__file__).resolve().parent.parent.joinpath('definitions.jsonl'))
terms = [definition.term for definition in definitions]
definitions_dict = {definition.term: definition for definition in definitions}

app = FastAPI()


@app.get("/terms")
def get_terms() -> TermList:
    return TermList(terms=terms)


@app.get("/definitions")
def get_definition(term: str) -> Definition:
    if term not in definitions_dict:
        raise HTTPException(status_code=404)
    
    return definitions_dict[term]


if __name__ == "__main__":
    uvicorn.run(app)
