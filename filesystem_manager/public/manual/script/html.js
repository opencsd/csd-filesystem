var Html = Class.create({
    initialize: function () {
        var lang = document.getElementById('language').value;

        // 소개
        jQuery.ajax({
            type: "POST",
            url: '/manual/' + lang + '/intro',
            success: function (data) {
                jQuery('#intro-html').html(data);
            },
            error: function (e) {
                alert(e.responseText);
            }
        });

        // 설치 가이드
        jQuery.ajax({
            type: "POST",
            url: '/manual/' + lang + '/install',
            success: function (data) {
                jQuery('#install-html').html(data);
            },
            error: function (e) {
                alert(e.responseText);
            }
        });

        // 클러스터
        jQuery.ajax({
            type: "POST",
            url: '/manual/' + lang + '/cluster',
            success: function (data) {
                jQuery('#cluster-html').html(data);
            },
            error: function (e) {
                alert(e.responseText);
            }
        });

        // 클러스터 볼륨
        jQuery.ajax({
            type: "POST",
            url: '/manual/' + lang + '/cluster/volume',
            success: function (data) {
                jQuery('#clusterVolume-html').html(data);
            },
            error: function (e) {
                alert(e.responseText);
            }
        });

        // 계정
        jQuery.ajax({
            type: "POST",
            url: '/manual/' + lang + '/account',
            success: function (data) {
                jQuery('#account-html').html(data);
            },
            error: function (e) {
                alert(e.responseText);
            }
        });

        // 서비스 프로토콜
        jQuery.ajax({
            type: "POST",
            url: '/manual/' + lang + '/share',
            success: function (data) {
                jQuery('#share-html').html(data);
            },
            error: function (e) {
                alert(e.responseText);
            }
        });

        // 노드
        jQuery.ajax({
            type: "POST",
            url: '/manual/' + lang + '/node',
            success: function (data) {
                jQuery('#node-html').html(data);
            },
            error: function (e) {
                alert(e.responseText);
            }
        });

        // 장애 대응: 공통 사항
        jQuery.ajax({
            type: "POST",
            url: '/manual/' + lang + '/troubleshoot/common',
            success: function (data) {
                jQuery('#troubleshoot_common-html').html(data);
            },
            error: function (e) {
                alert(e.responseText);
            }
        });

        // 장애 대응: 이벤트에 대한 장애
        jQuery.ajax({
            type: "POST",
            url: '/manual/' + lang + '/troubleshoot/events',
            success: function (data) {
                jQuery('#troubleshoot_event-html').html(data);
            },
            error: function (e) {
                alert(e.responseText);
            }
        });

        // 장애 대응: 상태에 대한 장애
        jQuery.ajax({
            type: "POST",
            url: '/manual/' + lang + '/troubleshoot/status',
            success: function (data) {
                jQuery('#troubleshoot_status-html').html(data);
            },
            error: function (e) {
                alert(e.responseText);
            }
        });

        // I/O 장애
        jQuery.ajax({
            type: "POST",
            url: '/manual/' + lang + '/troubleshoot/ioservice',
            success: function (data) {
                jQuery('#troubleshoot_ioservice-html').html(data);
            },
            error: function (e) {
                alert(e.responseText);
            }
        });

        // FAQ
        jQuery.ajax({
            type: "POST",
            url: '/manual/' + lang + '/questions/windows',
            success: function (data) {
                jQuery('#questions_windows-html').html(data);
            },
            error: function (e) {
                alert(e.responseText);
            }
        });

        if (window.location.hash == '')
        {
            document.getElementById('intro').style.display = "block";
        }

        this.contents = $('contents');

        var allElements = document.getElementsByTagName('label');

        for (var i=0, n=allElements.length; i<n; i++)
        {
            if (allElements[i].clientHeight > 50)
            {
                allElements[i].style.fontSize = '14px';
            }
        }

        var allElements = document.getElementsByTagName('a');

        for (var i=0, n=allElements.length; i<n; i++)
        {
            if (allElements[i].clientHeight > 50)
            {
                allElements[i].style.fontSize = '12px';
            }
        }

        jQuery('.tabs .tab-links a').on('click', function (e) {
            var currentAttrValue = jQuery(this).attr('href');

            // Show/Hide Tabs
            jQuery('.tabs ' + currentAttrValue).show().siblings().hide();

            jQuery(this).parent('li').addClass('active').siblings().removeClass('active');

            var x = document.getElementsByClassName("content");

            for (var i=0; i<x.length; i++)
            {
               x[i].style.display = "none";
               x[i].removeClassName('selected_chapter');
            }

            if (currentAttrValue == '#AdminManual')
            {
                document.getElementById('intro').style.display = "block";
                window.scroll(0, 0);
            }
            else if (currentAttrValue == '#OperationManual')
            {
                document.getElementById('troubleshoot_common').style.display = "block";
                window.scroll(0, 0);
            }

            e.preventDefault();
        });

        this.contents.on('click', 'li', this.click.bind(this));

        $('content').on('click', 'a', this.referenceClicked.bind(this));

        this.load();
        this.windowResized();

        window.onresize = this.windowResized.bind(this);

        this.hash = typeof(this.hash) === 'undefined'
                    ? ''
                    : window.location.hash;

        new PeriodicalExecuter(function (pe) {
            var h = window.location.hash;

            if (h && this.hash !== h)
            {
                this.load();
                this.hash = h;
            }
        }.bind(this), 0.5);
    },
    load: function () {
        var a;
        var hash = decodeURIComponent(window.location.hash);

        if (!hash)
        {
            a = this.contents.down('a');
            this.showChapter(this.getHref(a));
            this.select(a.up('li'));
            return;
        }

        hash = hash.substring(1);

        a = this.contents.select('a').find(function (each) {
            return each.getAttribute('href').endsWith(hash);
        });

        if (a) {
            this.showChapter(hash);
            var li = a.up('li');
            this.select(li);

            while (li)
            {
                if (li.hasClassName('closed'))
                {
                    li.removeClassName('closed');
                    li.addClassName('opened');
                }

                li = li.up('li');
            }

            return;
        }
        else if (hash)
        {
            this.showChapter(hash);
        }
    },
    showChapter: function (href) {
        var i = href.indexOf('.');
        var chapter = $(href.substring(0, i));

        if (!chapter) 
        {
            return;
        }

        $('content').select('.selected_chapter').each(function (each) {
            each.removeClassName('selected_chapter');
        });

        chapter.addClassName('selected_chapter');

        i = href.indexOf('#');

        if (i !== -1)
        {
            var title_url = href.substring(i + 1);
            var element;

            chapter
                .select('h1,h2,h3,h4,h5')
                .forEach(
                    function(e, i){
                         if (title_url === e.innerText)
                         {
                             element = e;
                             return;
                         }
                     }
                );

            if (element)
            {
                element.scrollTo();
                this.fadeIn(element);
            }
        }
        else
        {
            window.scroll(0, 0);
        }
    },
    fadeIn: function (element) {
        if (element.getOpacity() != 1)
        {
            return;
        }

        element.setOpacity(0.1);
        var opacity = 10;

        new PeriodicalExecuter(function (pe) {
            if (opacity > 100)
            {
                pe.stop();
                element.setOpacity(1);
            }
            else
            {
                element.setOpacity(opacity / 100);
                opacity += 20;
            }
        }.bind(this), 0.1);
    },
    windowResized: function () {
        this.contents.setStyle({
            height: document.viewport.getHeight() + 'px'
        });
    },
    click: function (event) {
        var a = event.findElement('a');

        if (a) {
            this.select(a.up('li'));
            var href = this.getHref(a);

            if (href == '#AdminManual')
            {
                document.getElementById('intro').style.display = "block";
                window.scroll(0, 0);
            }
            else if (href == '#OperationManual')
            {
                document.getElementById('troubleshoot_common').style.display = "block";
                window.scroll(0, 0);
            }
            else
            {
                document.getElementById('intro').style.display = "none";
                document.getElementById('troubleshoot_common').style.display = "none";
                window.location.hash = href;
                this.load();
            }
        }

        event.stop();
    },
    referenceClicked: function (event) {
        if (!event.findElement('#index_group'))
        {
            var hashText = this.getHref(event.findElement('a'));

            if (hashText.indexOf('xhtml') != -1)
            {
                window.location.hash = this.getHref(event.findElement('a'));
                this.load();
            }
            else
            {
                window.open(hashText);
            }
        }
        else
        {
            $(this.getHref(event.findElement('a')).substring(1)).scrollTo();
        }

        event.stop();
    },
    select: function (item) {
        if (this.selected)
        {
            this.selected.removeClassName('selected');
        }

        item.addClassName('selected');
        this.selected = item;
    },
    getHref: function (a) {
        var result = a.getAttribute('href');

        return result;
    }
});

document.observe(
    'dom:loaded',
    function (event)
    {
        new Html();
        new Search();
    }
);
