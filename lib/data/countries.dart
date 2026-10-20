class CountryDialCode {
  const CountryDialCode({
    required this.name,
    required this.iso2,
    required this.dialCode,
    required this.flag,
    required this.phoneLength,
  });

  final String name;
  final String iso2;
  final String dialCode;
  final String flag;
  final int phoneLength;
}

const indiaCountry = CountryDialCode(
  name: 'India',
  iso2: 'IN',
  dialCode: '+91',
  flag: '🇮🇳',
  phoneLength: 10,
);

const countries = <CountryDialCode>[
  indiaCountry,
  CountryDialCode(
    name: 'United States',
    iso2: 'US',
    dialCode: '+1',
    flag: '🇺🇸',
    phoneLength: 10,
  ),
  CountryDialCode(
    name: 'United Kingdom',
    iso2: 'GB',
    dialCode: '+44',
    flag: '🇬🇧',
    phoneLength: 10,
  ),
  CountryDialCode(
    name: 'United Arab Emirates',
    iso2: 'AE',
    dialCode: '+971',
    flag: '🇦🇪',
    phoneLength: 9,
  ),
  CountryDialCode(
    name: 'Saudi Arabia',
    iso2: 'SA',
    dialCode: '+966',
    flag: '🇸🇦',
    phoneLength: 9,
  ),
  CountryDialCode(
    name: 'Qatar',
    iso2: 'QA',
    dialCode: '+974',
    flag: '🇶🇦',
    phoneLength: 8,
  ),
  CountryDialCode(
    name: 'Singapore',
    iso2: 'SG',
    dialCode: '+65',
    flag: '🇸🇬',
    phoneLength: 8,
  ),
  CountryDialCode(
    name: 'Australia',
    iso2: 'AU',
    dialCode: '+61',
    flag: '🇦🇺',
    phoneLength: 9,
  ),
  CountryDialCode(
    name: 'Canada',
    iso2: 'CA',
    dialCode: '+1',
    flag: '🇨🇦',
    phoneLength: 10,
  ),
  CountryDialCode(
    name: 'Nepal',
    iso2: 'NP',
    dialCode: '+977',
    flag: '🇳🇵',
    phoneLength: 10,
  ),
];
