var Search = Class.create({
    initialize: function () {
        $('search').on('submit', this.search.bind(this));

        this.searchInputPanel = $('search_input_panel');

        this.searchInputPanel.on('click', 'input.close', function (event) {
            $(document.body).removeClassName('in_search');
        });

        this.searchPanel = $('search_panel');

        this.searchPanel.on('click', 'div > h1', function (event) {
            event.findElement('div').toggleClassName('expanded');
        });

        this.searchResult = $('search_result');
    },
    search: function (event) {
        var keyword = $('search').down('input').value;

        if (keyword) {
            keyword = keyword.toLowerCase();

            if (!this.contents)
            {
                this.contents = $A();

                $$('.content').each(function (each) {
                    this.loadContent(each);
                }.bind(this));

                this.searchResult.update('검색 결과');
            }
            else
            {
                this.searchResult.update('검색 결과');
            }

            $(document.body).addClassName('in_search');

            var count = this.contents.size();
            var contents = this.contents;
            var i = 0;

            new PeriodicalExecuter(function (pe) {
                try
                {
                    this.searchChapter(contents[i], keyword);
                }
                catch (e)
                {
                    //console.log(e);
                }

                if (++i == count)
                {
                    var div = this.searchResult.down('div');

                    if (div)
                    {
                        div.addClassName('expanded');
                    }
                    else
                    {
                        this.searchResult.update(this.searchResult.getAttribute('data-i18n-no'));
                    }

                    pe.stop();
                }
            }.bind(this), 0.01);
        }

        event.stop();
    },
    searchChapter: function (content, keyword) {
        var count = 0;
        var elements = $A();
        var keywordLength = keyword.length;

        content.elements.each(function (each) {
            var text = each.text;
            var plain = each.plain;
            var i = plain.indexOf(keyword);
            var j = 0;
            var element;

            while (i !== -1)
            {
                count++;

                if (!element)
                {
                    element = text.substring(0, i) + '<mark>' + text.substring(i, i + keywordLength) + '</mark>';
                }
                else
                {
                    element += text.substring(j, i) + '<mark>' + text.substring(i, i + keywordLength) + '</mark>';
                }

                j = i + keywordLength;
                i = plain.indexOf(keyword, j);
            }

            if (element) {
                element += text.substring(j);
                elements.push({
                    id: each.id,
                    text: element
                });
            }
        });

        if (count > 0) {
            var html = '<div>';
            html += '<h1>' + content.title + '<span>' + count + '</span></h1><ul>';

            elements.each(function (each) {
                var position = new Array();
                var pos = each.text.indexOf('<mark>'+keyword);

                while (pos > -1)
                {
                    position.push(pos);
                    pos =  each.text.indexOf('<mark>'+keyword, pos + 1);
                }

                if (position.length > 1)
                {
                    for (var i=0; i<position.length; i++)
                    {
                        var resultText;

                        if (position[i+1] > position[i]+80)
                        {
                            resultText = each.text.substring(position[i], position[i+1]);
                        }
                        else
                        {
                            resultText = each.text.substring(position[i], position[i]+80);
                            i++;
                        }

                        var resultIndexOf=resultText.indexOf('\n');

                        if (resultIndexOf == -1)
                        {
                            resultText = resultText.substring(0, 80);
                        }
                        else
                        {
                            resultText = resultText.substring(0,resultIndexOf);
                        }

                        if (resultText.length == 80)
                        {
                            html += '<li><a href="' + content.id + '.xhtml#' + content.title + '" onclick="return false;">' + resultText + '...</a></li>';
                        }
                        else
                        {
                            html += '<li><a href="' + content.id + '.xhtml#' + content.title + '" onclick="return false;">' + resultText + '</a></li>';
                        }
                    }
                }
                else
                {
                    var texttoLower = each.text.toLowerCase();
                    var resultIndexOf = texttoLower.indexOf('<mark>'+keyword);
                    var resultText = each.text.substring(resultIndexOf, resultIndexOf+80);
                    var resultIndexOf = resultText.indexOf('\n');

                    if (resultIndexOf == -1)
                    {
                        resultText=resultText.substring(0, 80);
                    }
                    else
                    {
                        resultText=resultText.substring(0,resultIndexOf);
                    }

                    if (resultText.length == 80)
                    {
                        html += '<li><a href="' + content.id + '.xhtml#' + content.title + '" onclick="return false;">' + resultText + '...</a></li>';
                    }
                    else
                    {
                        html += '<li><a href="' + content.id + '.xhtml#' + content.title + '" onclick="return false;">' + resultText + '</a></li>';
                    }
                }
            });

            html += '</ul></div>';
            this.searchResult.insert(html);
        }
    },
    loadContent: function (div) {
        var content;
        var subID;
        div.select('h1,h2,h3,h4,h5').each(function (each) { 
            var title = this.escapeText(each);

            content = {
                id: div.getAttribute('id'),
                title: title,
                elements: $A()
            };

            content.elements.push({
                id: each.getAttribute('id'),
                text: title,
                plain: title.toLowerCase()
            });

            this.contents.push(content);

        }.bind(this));
    },
    escapeText: function (element) {
        var result = '';
        var nodes = element.childNodes;
        var length = nodes.length;

        for (var i=0; i<length; i++)
        {
            var node = nodes[i];

            if (node.nodeType === 3)
            {
                result += node.nodeValue.replace('<', '&lt;').replace('>', '&gt;');
            }
            else
            {
                var tagName = node.tagName;
                var className = node.getAttribute('class');

                if (className !== 'mark index'
                    && className !== 'step1_n'
                    && tagName !== 'ins')
                {
                    result += this.escapeText(node) + '';
                }
            }
        }

        return result;
    }
});
