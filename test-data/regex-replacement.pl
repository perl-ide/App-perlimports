use IP::Random;
s/($RE{net}{IPv4})/${\( $store{$1} ||= IP::Random::random_ipv4() )}/g;
