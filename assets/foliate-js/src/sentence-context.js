const normalize = text => text.replace(/\s+/g, ' ').trim()
const abbreviation = text => /\b(?:Mr|Mrs|Ms|Dr|Prof|Sr|Jr|St|vs|e\.g|i\.e|[A-Z])\.$/i.test(text.trim())

// Offsets, rather than a text search, distinguish repeated words in a paragraph.
export const sentenceAt = (text, start, end, locale) => {
    if (!text || start < 0 || end <= start || end > text.length) return ''
    let boundaries
    if (typeof Intl !== 'undefined' && typeof Intl.Segmenter === 'function') {
        try {
            boundaries = Array.from(new Intl.Segmenter(locale || undefined,
                { granularity: 'sentence' }).segment(text), part =>
                ({ start: part.index, end: part.index + part.segment.length }))
        } catch (_) { /* Old WebViews use punctuation boundaries below. */ }
    }
    {
        // Include explicit punctuation even when ICU treats a lowercase next
        // sentence as a continuation (common in OCR and informal writing).
        boundaries ??= []
        const pattern = /[。！？!?]+[”’」』）)"']*|\.[”’」』）)"']*(?=\s|$)|\n+/g
        let from = 0
        for (const match of text.matchAll(pattern)) {
            const to = match.index + match[0].length
            if (match[0] === '.' && abbreviation(text.slice(from, to))) continue
            boundaries.push({ start: from, end: to })
            from = to
        }
        if (from < text.length) boundaries.push({ start: from, end: text.length })
    }
    boundaries = Array.from(new Set(boundaries.map(part => part.end)))
        .sort((a, b) => a - b)
        .map((end, index, ends) => ({ start: index ? ends[index - 1] : 0, end }))
    // ICU may split a title such as Dr. from the following name.
    const merged = []
    for (const part of boundaries) {
        const previous = merged[merged.length - 1]
        if (previous && abbreviation(text.slice(previous.start, previous.end))) previous.end = part.end
        else merged.push({ ...part })
    }
    const first = merged.find(part => part.end > start)
    const last = merged.find(part => part.end >= end)
    return first && last ? normalize(text.slice(first.start, last.end)) : ''
}

export const rangeSentence = range => {
    if (!range || range.collapsed) return ''
    const block = node => (node.nodeType === 1 ? node : node.parentElement)
        ?.closest('p, li, dt, dd, blockquote, figcaption, pre, td, th, h1, h2, h3, h4, h5, h6, div, body')
    const before = range.cloneRange()
    const after = range.cloneRange()
    const first = block(range.startContainer)
    const last = block(range.endContainer)
    if (!first || !last) return ''
    before.selectNodeContents(first)
    before.setEnd(range.startContainer, range.startOffset)
    after.selectNodeContents(last)
    after.setStart(range.endContainer, range.endOffset)
    const textOf = current => {
        if (!first.querySelector('br') && !last.querySelector('br')) return current.toString()
        const fragment = current.cloneContents()
        for (const br of fragment.querySelectorAll('br')) br.replaceWith(' ')
        return fragment.textContent || ''
    }
    const prefix = textOf(before)
    const selected = textOf(range)
    const text = prefix + selected + textOf(after)
    const doc = range.startContainer.ownerDocument
    return sentenceAt(text, prefix.length, prefix.length + selected.length,
        doc.documentElement?.lang || undefined)
}
