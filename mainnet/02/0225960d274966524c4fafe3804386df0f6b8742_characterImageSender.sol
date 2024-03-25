/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;
// pilot m
contract characterImageSender {
    string public constant characterModel1 = "iVBORw0KGgoAAAANSUhEUgAAAFAAAABQCAMAAAC5zwKfAAAAG3RFWHRTb2Z0d2FyZQBDZWxzeXMgU3R1ZGlvIFRvb2zBp+F8AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAQlBMVEVbW1ssKSlaWloyMjJkZGSysrJMTEyNjY3///8AAAChoaFAQEBHR0cODg4PDw8DAwMFBQWbm5tZWVkCAgIlJSUHBwf5pH9bAAAEZ0lEQVRYw+3YyZYjKQyFYQMXpB+yhp7e/1V7ISDClYPDrtO7ZpEeTsZnCREMcbv93/77xkff8Tsg65XTd/wOGFdjHA56XcQE3G4g2SKRXg4S5A44ZnJf4cpeFyV3B8zmu9sNk5zXc5a7u5uZLETM5JdCPHf8roam6Fs8p/8onAMsUQNM9k60EK+AfoA5ovlF3OlfCvEMks19X/5OlF8JETvlnG2J7pLig+1XfzrELDvILbpOL5dBuN3I2czuonTfn+xZkBslQDt1pd2D11MmG+QsWw3QHo+78ZicVSFns7xFOIa32ax0fHwkYuYAZAtRZhb38clbYAxGHoHu7ivELBnm28O2Lc1B9Ag0M3NyiJLA7RfwKMtDEQACnN2IHwHeg3JHV+5pzLcoOHucg5U7XJklmDnnbGaRsG9wewu8MDWCOcpSzsYpyfPomaCDyS6E6EiSlE8BgqG79+5OxnQJXG2NY3eMk20zwougYe4wpjoT/qjljIwLS4u5e6aU3vvIAAzIvfc+BuTcoYz+I5Lg8cpiHgtyKTn33mEyvURY+Y9OKQN650KRMTnIc4Dwdxlj5l9KGSPn3CmlMC6CUUE5pZT7HuullDJy/gHAzzEegzcMydyROQXoGSacey+lRLAVShn9yjQboCMHCrlDKYxRIfc+oh+p5Sq49h/InVJggaNG0hQytUIppXN7DhylkHvvhTLGIEeIYzwNaqZcStkDnKjvrlPvpV8CQ9TcG8IYsxhj5LwqPTK951Ku7cIO0IAxRj+J620M62sBYiZhbkgCxui9lNJ772cQbhcDBDObYCykLKbP9sRhIHpce4Xfq/NdezgnvFfNwKfodtpGzNdXzigx18592ALnHucFMCVipt2bufOG6VmQlFJKzN2JThu7l0AYCUhtinovPhkhY7TWVj8qRs+d9+QhElJrbZnSHo9z0XJSeo4kjdZO5hqQO8L09vb2FHkSW2vMtBcJ4fFUXd57x97h7e3t2SPpESLTO1UkvT1/wiUtkXm7nbwXDsyQphjn+nUvO696QEqttdhnHvNMSu2V4zeqC4y9vyRBSqm95P35l6R5uW3xdQ++S3K2F2LcHtxe6kBJqhDgnA1JvAACtUoECMeAAfBnQaDWA1Q8tZiPL6h4Fd+eybQGJ0GAXnXMMhUX3xvfLm26VmySqiQkJujrr6j8k9K3WuvjjebWpgg7Qnd3MVf9lBKSHpCwuTqb+FmJ7N3dVVEM9gC/FmEHt7wKaf4MklyVOr0Z4Rd5b6+eWsRCrWLed5FvS4n9n5+B9U7zKMJcSAFFNBgttXuQT71TbHFkn+CxOJkZrU3Q/QuRKkVYuyASpNameMyFE2SDHyUNugfXTJVzS4nTMxsmuMrs/jFY6znj2f8p5dxaS2shdie8CHEG8WHOc2rRXS1TajmvqyeX0gKjWHM0frrH3FP88iLEVerFxc80Vq2+eL4y57yUUkp5eiGmpbU2f6axuvUj7/S87ARGLL+0+UMp7adGh/MvDhRXG5ZoCdMAAAAASUVORK5CYII=";
    string public constant characterModel2 = "iVBORw0KGgoAAAANSUhEUgAAAFAAAABQCAMAAAC5zwKfAAAAG3RFWHRTb2Z0d2FyZQBDZWxzeXMgU3R1ZGlvIFRvb2zBp+F8AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAQlBMVEVbW1taWlpMTEw2NjZkZGQsKSmysrKNjY3///8AAABAQEAyMjKhoaFHR0cPDw8DAwMFBQWbm5sCAgIODg4lJSUHBweHIE8KAAAE0klEQVRYw+3Y6ZacOAwF4DJ4u0Anme39X3WkK9mY6k7KVM78G850ilr4kGx5YR6P/4///sBXn+F3QLRXDJ/hd0C7GgWng/i+iBIJATGWRsr520EKVKtAFaXwzO9S3hejOEoKaGcEY8X7OatTaxGxmMhop0IcG773RnSxdnFM/1U4J7hbH2h7fRKLiTNgPcFg0TyJPf2pEEcQodTaL/8ksoMmwCHnUJpYq7SjvSn9td4OMcRykl2scXiZBtkbQUIslyglsPam3AWhvVLKSF74mylL+0mnMGc7oGO59Uw/8Jr0XmG6oYusnXPAWLr29pUoIGtPu5hipFeuXgOtGPEK5I09RBWlGbrHMeJg9CJ6BbLpBaQYdear5Qk8u+WlyHRhoDcj6hngFdSE48yYRqldZICnhzFYtuDMLAHPmZVtCdcOdq+BE1Mjc47SfiEUDEmO1eMgX8pEiJV1LOQQoFyLeDlnOSg8A7aj1bE2Gga7eISTYGHHYHPVE/7qCAFSqhNLixZ4wL4fx7EFXip6OPStnoQD2LfjuyWB1yuLtqJGte9BFeGMOXYLK/xxyHfymX73upPZLiIGA4G/923z/HdxtqCfyhm2SdB6UFS96NJix65iCEwWP7btNfggqJ2iFabeETQwEw8VLdisnyo4s6GxBVgTF5I9IOltmeJm7Yi8z4Jt/8F+0dAaKCKT1psgM8L9wOMeuO07y0UU7ZhgIcrZXTD2CPde4LD+7f0ktzmmQBOj7w3pWGcQ9J6Wej+OILeb2oWdYCG4HYPYTq2s5wLkTKqrCbgKQMWdA/EYQV2/5wLkNOOgLaRozOHHjYcBa/HYV/i+Ol+Ol3PCZ1WR6mItwzbCX995RrG51vdhDfQ9Du57KcFm2r6ZGzdMuOullLQnuTvRtOvzXukNbmOMtmZ9Eu+AoLZty2JZG1hw8e7UjYW3LAom+O7wLB0D+c29jE2EL9JekD3C9PHxcY+kKGDBsgyi7/hgHm61I0PUAl+ad+4d6N0tnK2B3ohDj6SP+0+4YNIKRh9ug/fGAzMsxMT9DdoItl34mx5FgoWzoh8pLe88fiNmBTcDi3Uz62lZcDsyOf7U6300d/G+x/5c9fimFSJibzsHcaeY+6AQkKe5xeezIejNriReE1kOJWGg9e85IfDhaSJMOOWHiAbG2kXbIdUc8Rf3Db9+hhq0SJCigir0WUbAiG8L1vhrktGYpJgGSBAO1vZvlBj/kZ4RUPWfmg2MedXm498K9Aj5uAhf9RNB+b020tcka8X7t4Mi/sjIrBaCmW2gnoCas5I0fwqu7T8FM4cs25NPPPJBdk/BlUllz/zJyx5SvIK8VJQIH3eW78KU+cPcEv8CzGe68rt1zdmDYb1rLFo/WNIygBqlfoenkiZAxEx5XXN18Fyc9MzXmTX35tEYrjmfGQukpntItuqd2xqZCx3Ucshx9VZ6ClFqlU28EnJQvRSCXjz8Pxugra2VYGZm2vnXQSLfVMP0z0cZPZ2x+yiHeba2yiXa8HJBZEWMk0KGIv7X+lJ6k+CC2J5Hpa0aaJ21VvagqhgDxOOylUypeRTRpv/oIG8jy0BqI5whDrOMguk8/Dy4t9jEyGFO0D5WMPFrjfQCRvOWdpzg0sBsIkG/EW9sv9eRZnuxfwHzUF3h/K3wpQAAAABJRU5ErkJggg==";
    string public constant characterModel3 = "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";
    string public constant characterModel4 = "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";
    string public constant characterModel5 = "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";
}