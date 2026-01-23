## 在动作栏显示实时实体数量

title @a actionbar [\
  {\
    "translate": "tick.show.entity.dfl.entity.num",\
    "fallback": "实体数量：%s",\
    "color": "yellow",\
    "with": [\
      {\
        "score": {\
          "name": "entity",\
          "objective": "dfl_scoreboard"\
        },\
        "color": "red"\
      }\
    ]\
  }\
]
