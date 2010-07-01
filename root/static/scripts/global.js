YUI().use("io-form", "json", "substitute", "datatype-date", "overlay", "event-delegate", function(Y) {
    var header = Y.one('.container header');
    var table  = Y.one('.container table.cal');
    var footer = Y.one('.container footer');
    var height = footer.get('winHeight') - header.get('offsetHeight') - footer.get('offsetHeight');
    // XX this should really be applied to the TDs, divided by 5?
    table.setStyle('height', height + 'px');

    var blank_content = "<form method=\"post\" action=\"/calendar/note{id}\"><input type=\"hidden\" name=\"date\" value=\"{date}\"><textarea style=\"width: 100%; height: 90%;\" name=\"note\">{note}</textarea><div><input type=\"submit\" value=\"Save note\"></div></form>";

    var overlay = new Y.Overlay({
        width: "80%",
        height: "60%",
        zIndex: 2,
        headerContent: "Note for {date}",
        bodyContent:  blank_content
    });

    overlay.render("div.yui3-main");
    overlay.set("centered", true);
    overlay.hide();

    function updateDay(date, markup) {
        var td = Y.one('#cal-' + date);
        if ( td === null )
            return;
        var node = Y.Node.create(markup);
        td.set( 'innerHTML', node.get('innerHTML') );
    }

    function deleteNote(e) {
        e.halt();
        var td   = e.target.ancestor('td');
        var link = e.target.ancestor('a.rest-delete');
        var date = td.get('id').substr(4);

        var cfg  = {
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json',
            },
            on: {
                success: function(id, o, args) {
                    var json = Y.JSON.parse( o.responseText );
                    if ( json && json.markup )
                        updateDay(date, json.markup);
                }
            },
            data: Y.JSON.stringify({ ok: "ok" })
        };
        Y.io( link.get('href'), cfg );
    }

    Y.delegate('submit',
        function(e) {
            e.halt();
            var form = e.target;
            var date = form.get('date').get('value');
            var data = Y.JSON.stringify({
                "date": date,
                "note": form.get('note').get('value')
            });

            var cfg  = {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                on: {
                    start: function() { Y.log('form start') },
                    error: function() { Y.log('form error') },
                    success: function(id, o, args) {
                        var json = Y.JSON.parse( o.responseText );
                        if ( json && json.markup )
                            updateDay(date, json.markup);
                    },
                    complete: function() { Y.log('form complete') },
                    end: function() { Y.log('form end'); overlay.hide(); },
                },
                data: data
            };
            Y.io( form.get('action'), cfg );
        },
        document.body, '.yui3-overlay-content form'
    );

    Y.on('click',
        function(e) {
            var ov_ancestor = e.target.ancestor('.yui3-overlay-content');
            if ( ov_ancestor === null )
                overlay.hide();
        },
        document.body
    );

    Y.delegate( 'click',
        function(e) {
            Y.log(e.target.get('tagName'));
            e.halt();

            if ( overlay.get('visible') === true ) {
                overlay.hide();
                return;
            }

            // This is totally assy.
            if ( e.target.get('parentNode').get('tagName').toUpperCase() === 'A' &&
                 e.target.get('parentNode').hasClass('rest-delete') )
            {
                return deleteNote(e);
            }

            var td = e.target.get('tagName').toUpperCase() === 'TD' ?
                e.target : e.target.ancestor('td');
            if ( td === null )
                return;
            
            var note;
            if ( e.target.get('tagName').toUpperCase() === 'P' ) {
                var li = e.target.ancestor('li.note');
                note = {
                    id:      li.get('id').substr(5), // lop off note-
                    content: e.target.get('innerHTML')
                };
            }

            var date_id = td.get('id');
            if ( /cal-\d{4}-\d{2}-\d{2}/.test(date_id) ) {
                var date = new Date(
                    date_id.substr(4,4),
                    date_id.substr(9,2) - 1,
                    date_id.substr(12,2)
                );
                if ( note ) {
                    overlay.set(
                        'headerContent',
                        "Edit note for " + Y.DataType.Date.format( date, { format: '%B %e, %Y' } ) );
                    overlay.set(
                        'bodyContent',
                        Y.Lang.substitute( blank_content, { date: date_id.substr(4), id: "/" + note.id, note: note.content } )
                    );
                } else {
                    overlay.set('headerContent', "Add a note for " + Y.DataType.Date.format( date, { format: '%B %e, %Y' } ) );
                    overlay.set(
                        'bodyContent',
                        Y.Lang.substitute( blank_content, { date: date_id.substr(4), note: "", id: "" } )
                    );
                }

                overlay.show();
                Y.one('.yui3-overlay-content textarea').focus();
            }
        },
        'table.cal', 'td'
    );
});

