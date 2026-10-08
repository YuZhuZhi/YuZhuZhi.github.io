#import "notes.typ": entries
#import "questions.typ": all-questions
#import "../../index.typ": template, tufted
#show: template.with(
    title: "Systematic Algebraic Method to Identify Clifford Operations for Quantum Error-Correction Codes 讲稿",
    description: "",
)

#set par(justify: true, leading: 0.6em, spacing: 0.9em)
#show heading.where(level: 1): set text(size: 20pt, weight: "bold", fill: rgb("#0B5E1F"))

#for (i, entry) in entries.enumerate() {
  let questions = all-questions.at(i)
  heading(level: 1, [第 #str(i + 1) 页：#entry.title])

  entry.paragraphs

  block(
    width: 100%,
    fill: rgb("#F2FBF3"),
    stroke: 0.7pt + rgb("#CBE6D0"),
    radius: 4pt,
    inset: 12pt,
  )[
    #set text(size: 11pt)
    #set par(leading: 0.45em, spacing: 0.45em)
    #for (j, qa) in questions.enumerate() [
      *可能提问 #str(j + 1)：* #qa.question

      *参考回答：* #qa.answer

    ]
  ]

}
