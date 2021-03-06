use Cro::HTTP::Client;
use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Cro::WebApp::Template;
use Test;

my constant TEST_PORT = 30209;

template-location $*PROGRAM.parent.add('test-data');

my $application = route {
    get -> {
        template 'macro-1.crotmp', { foo => 'xxx', bar => 'yyy' };
    }
    get -> 'nodata' {
        template 'literal.crotmp';
    }
    get -> 'ct1' {
        template 'macro-1.crotmp', { foo => 'abc', bar => 'def' },
                content-type => 'text/plain';
    }
    get -> 'ct2' {
        template 'literal.crotmp', content-type => 'text/plain';
    }
}
my $server = Cro::HTTP::Server.new(:$application, :host('localhost'), :port(TEST_PORT));
$server.start;
LEAVE try $server.stop;

my $resp;
lives-ok { $resp = await Cro::HTTP::Client.get("http://localhost:{TEST_PORT}/") };
is $resp.content-type.type-and-subtype, 'text/html',
        'Got expected default content type';
is norm-ws(await $resp.body-text), norm-ws(q:to/EXPECTED/), 'Request to a template-served route works';
      <ul>
        <li>
        <strong>xxx</strong>
          yyy
        </li>
        <li>
          <strong>xxx</strong>
          yyy
        </li>
      </ul>
    EXPECTED

lives-ok { $resp = await Cro::HTTP::Client.get("http://localhost:{TEST_PORT}/nodata") };
is $resp.content-type.type-and-subtype, 'text/html',
        'Got expected default content type';
is norm-ws(await $resp.body-text), norm-ws(q:to/EXPECTED/), 'Can use template without data';
      <div>
        <strong>Hello, I'm a template!</strong>
      </div>
    EXPECTED

lives-ok { $resp = await Cro::HTTP::Client.get("http://localhost:{TEST_PORT}/ct1") };
is $resp.content-type.type-and-subtype, 'text/plain',
        'Got explicitly set content type when data';
is norm-ws(await $resp.body-text), norm-ws(q:to/EXPECTED/), 'Template rendered OK';
      <ul>
        <li>
        <strong>abc</strong>
          def
        </li>
        <li>
          <strong>abc</strong>
          def
        </li>
      </ul>
    EXPECTED

lives-ok { $resp = await Cro::HTTP::Client.get("http://localhost:{TEST_PORT}/ct2") };
is $resp.content-type.type-and-subtype, 'text/plain',
        'Got explicitly set content type when no data';
is norm-ws(await $resp.body-text), norm-ws(q:to/EXPECTED/), 'Template rendered OK';
      <div>
        <strong>Hello, I'm a template!</strong>
      </div>
    EXPECTED

sub norm-ws($str) {
    $str.subst(:g, /\s+/, '')
}

done-testing;
