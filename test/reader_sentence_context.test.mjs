import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { runInNewContext } from 'node:vm'

const { JSDOM } = createRequire(`${process.env.MODU_JSDOM_ROOT}/package.json`)('jsdom')
const source = await readFile(new URL('../assets/foliate-js/src/sentence-context.js', import.meta.url), 'utf8')
const { sentenceAt, rangeSentence } = await import(`data:text/javascript;base64,${Buffer.from(source).toString('base64')}`)
const fallback = runInNewContext(source.replaceAll('export const ', 'const ') + '\nsentenceAt', { Intl: {} })
const layout = await readFile(new URL('../assets/foliate-js/src/text-page-layout.js', import.meta.url), 'utf8')
const { preparePageRuns } = await import(`data:text/javascript;base64,${Buffer.from(layout).toString('base64')}`)

test('sentence extraction respects actual offsets, quotes, abbreviations and long sentences', () => {
    for (const extract of [sentenceAt, fallback]) {
        for (const [text, word, expected] of [
            ['First word. Second word belongs here! Last.', 'word', 'Second word belongs here!'],
            ['上一句。这个单词属于这一句！”下一句。', '单词', '这个单词属于这一句！”'],
            ['Before. Dr. Smith paid 3.14 dollars. After.', 'Smith', 'Dr. Smith paid 3.14 dollars.'],
            [`Before. ${'long '.repeat(180)}word ends here. After.`, 'word', `${'long '.repeat(180)}word ends here.`],
            ['Before. Sentence without punctuation', 'without', 'Sentence without punctuation'],
        ]) {
            const start = text.lastIndexOf(word)
            assert.equal(extract(text, start, start + word.length), expected)
        }
        assert.equal(extract('text', 2, 2), '')
        assert.equal(extract('text', -1, 2), '')
    }
})

test('inline tags and page runs preserve sentence and selected word', () => {
    for (const [html, expected] of [
        ['Before. This <em id="word">word</em> belongs here. After.', 'This word belongs here.'],
        ['先前一句。这是<strong id="word">单词</strong>的语境！最后一句。', '这是单词的语境！'],
        ['Before. We <span id="word"><b>collect</b> words</span> here. After.', 'We collect words here.'],
        ['Before. A sentence with<br><span id="word">word</span> on another line. After.', 'A sentence with word on another line.'],
    ]) {
        const doc = new JSDOM(`<html lang="en"><body><p>${html}</p><p>Other paragraph.</p></body></html>`).window.document
        for (const aligned of [false, true]) {
            if (aligned) preparePageRuns(doc)
            const range = doc.createRange()
            range.selectNodeContents(doc.querySelector('#word'))
            const selected = range.toString(), before = doc.body.innerHTML
            assert.equal(rangeSentence(range), expected)
            assert.equal(range.toString(), selected)
            assert.equal(doc.body.innerHTML, before)
        }
    }
    assert.equal(rangeSentence(null), '')
})
