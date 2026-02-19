public with sharing class SHF_AddressMatcherHelper {

    // ---------- Public API (original signature kept) ----------
    @AuraEnabled(cacheable=true)
    public static List<AddressMatchResult> matchAddress(String requestedAddress) {
        return matchAddressInternal(requestedAddress, null);
    }

    // ---------- Optional API (no overload, different name) ----------
    @AuraEnabled(cacheable=true)
    public static List<AddressMatchResult> matchAddressWithExclusion(String requestedAddress, Id excludeCollateralId) {
        return matchAddressInternal(requestedAddress, excludeCollateralId);
    }

    // ---------- Internal ----------
    private static List<AddressMatchResult> matchAddressInternal(String requestedAddress, Id excludeCollateralId) {

        List<AddressMatchResult> results = new List<AddressMatchResult>();
        if (String.isBlank(requestedAddress)) return results;

        String normalizedInput = normalize(requestedAddress);
        List<String> inputWords = tokenize(normalizedInput);
        if (inputWords.isEmpty()) return results;

        List<Collateral__c> collaterals;

        if (excludeCollateralId == null) {
            collaterals = [
                SELECT Id, Name, Full_Address__c
                FROM Collateral__c
                WHERE Full_Address__c != null
                AND isActive__c = true
            ];
        } else {
            collaterals = [
                SELECT Id, Name, Full_Address__c
                FROM Collateral__c
                WHERE Full_Address__c != null
                AND isActive__c = true
                AND Id != :excludeCollateralId
            ];
        }


        Map<Id, AddressMatchResult> bestByCollateral = new Map<Id, AddressMatchResult>();

        for (Collateral__c c : collaterals) {
            String normalizedDb = normalize(c.Full_Address__c);
            if (String.isBlank(normalizedDb)) continue;

            List<String> dbWords = tokenize(normalizedDb);
            if (dbWords.isEmpty()) continue;

            // 1) EXACT (100%)
            if (normalizedInput == normalizedDb) {
                upsertBest(bestByCollateral, c.Id, buildResult(
                    requestedAddress, c.Full_Address__c, 'EXACT', 100,
                    c.Id, c.Name
                ));
                continue;
            }

            // Pre-calc fuzzy
            Decimal fuzzy = calculateFuzzySimilarity(normalizedInput, normalizedDb, inputWords, dbWords);

            // 2) SAME_SEQUENCE (words in same order) + threshold
            if ((isSubsequence(inputWords, dbWords) || isSubsequence(dbWords, inputWords)) && fuzzy >= 65) {
                Decimal boosted = Math.min(Decimal.valueOf('99'), fuzzy + 10);
                upsertBest(bestByCollateral, c.Id, buildResult(
                    requestedAddress, c.Full_Address__c, 'SAME_SEQUENCE', boosted,
                    c.Id, c.Name
                ));
                continue;
            }

            // 3) REORDERED (same words, different order) using multiset
            if (sameWordMultiset(inputWords, dbWords)) {
                upsertBest(bestByCollateral, c.Id, buildResult(
                    requestedAddress, c.Full_Address__c, 'REORDERED', 95,
                    c.Id, c.Name
                ));
                continue;
            }

            // 4) FUZZY (>= 65)
            if (fuzzy >= 65) {
                upsertBest(bestByCollateral, c.Id, buildResult(
                    requestedAddress, c.Full_Address__c, 'FUZZY', fuzzy,
                    c.Id, c.Name
                ));
            }
        }

        results.addAll(bestByCollateral.values());
        results.sort(); // Comparable in wrapper

        // cap top 50 (Apex has no subList)
        if (results.size() > 50) {
            List<AddressMatchResult> capped = new List<AddressMatchResult>();
            for (Integer i = 0; i < 50; i++) {
                capped.add(results[i]);
            }
            return capped;
        }
        system.debug('found ' + results.size() + ' matches for input: ' + results);
        return results;
    }

    // ------------------- Wrapper -------------------
    public class AddressMatchResult implements Comparable {
        @AuraEnabled public String requestedAddress;
        @AuraEnabled public String matchedAddress;
        @AuraEnabled public String matchType;
        @AuraEnabled public Decimal matchPercentage;

        @AuraEnabled public Id collateralId;
        @AuraEnabled public String collateralName;

        // Sort: match% desc, then type priority asc (EXACT first), then Id asc
        public Integer compareTo(Object otherObj) {
            AddressMatchResult o = (AddressMatchResult) otherObj;

            // matchPercentage DESC
            if (this.matchPercentage > o.matchPercentage) return -1;
            if (this.matchPercentage < o.matchPercentage) return 1;

            // priority ASC (1 is best)
            Integer pThis = typePriority(this.matchType);
            Integer pOther = typePriority(o.matchType);
            if (pThis < pOther) return -1;
            if (pThis > pOther) return 1;

            // tie breaker
            String a = String.valueOf(this.collateralId);
            String b = String.valueOf(o.collateralId);
            return a.compareTo(b);
        }
    }

    private static Integer typePriority(String t) {
        if (t == 'EXACT') return 1;
        if (t == 'SAME_SEQUENCE') return 2;
        if (t == 'REORDERED') return 3;
        return 4; // FUZZY
    }

    // ------------------- Builders -------------------
    private static AddressMatchResult buildResult(
        String req, String match, String type, Decimal percent,
        Id collateralId, String collateralName
    ) {
        AddressMatchResult r = new AddressMatchResult();
        r.requestedAddress = req;
        r.matchedAddress = match;
        r.matchType = type;
        r.matchPercentage = (percent == null ? 0 : percent).setScale(2);
        r.collateralId = collateralId;
        r.collateralName = collateralName;
        return r;
    }

    private static void upsertBest(Map<Id, AddressMatchResult> bestByCollateral, Id key, AddressMatchResult candidate) {
        if (!bestByCollateral.containsKey(key)) {
            bestByCollateral.put(key, candidate);
            return;
        }

        AddressMatchResult existing = bestByCollateral.get(key);

        Integer ep = typePriority(existing.matchType);
        Integer cp = typePriority(candidate.matchType);

        if (cp < ep) {
            bestByCollateral.put(key, candidate);
        } else if (cp == ep && candidate.matchPercentage > existing.matchPercentage) {
            bestByCollateral.put(key, candidate);
        }
    }

    // ------------------- Matching helpers -------------------

    private static List<String> tokenize(String normalized) {
        List<String> out = new List<String>();
        if (String.isBlank(normalized)) return out;

        Set<String> stop = new Set<String>{
            'the','of','and','to','in','on','at','near','opp','opposite','behind','beside','next'
        };

        for (String w : normalized.split('\\s+')) {
            if (String.isBlank(w)) continue;
            if (stop.contains(w)) continue;
            out.add(w);
        }
        return out;
    }

    // a is subsequence of b (order preserved)
    private static Boolean isSubsequence(List<String> a, List<String> b) {
        if (a.isEmpty()) return true;
        Integer i = 0;
        for (Integer j = 0; j < b.size() && i < a.size(); j++) {
            if (a[i] == b[j]) i++;
        }
        return i == a.size();
    }

    // Multiset equality (word frequency)
    private static Boolean sameWordMultiset(List<String> a, List<String> b) {
        if (a.size() != b.size()) return false;
        Map<String, Integer> ca = wordCount(a);
        Map<String, Integer> cb = wordCount(b);
        if (ca.size() != cb.size()) return false;

        for (String k : ca.keySet()) {
            if (!cb.containsKey(k)) return false;
            if (cb.get(k) != ca.get(k)) return false;
        }
        return true;
    }

    private static Map<String, Integer> wordCount(List<String> tokens) {
        Map<String, Integer> m = new Map<String, Integer>();
        for (String t : tokens) {
            m.put(t, (m.containsKey(t) ? m.get(t) : 0) + 1);
        }
        return m;
    }

    // Fuzzy similarity: max(tokenOverlap%, levenshteinCharSim%)
    private static Decimal calculateFuzzySimilarity(String normA, String normB, List<String> aTokens, List<String> bTokens) {
        Decimal tokenSim = tokenOverlapPercent(aTokens, bTokens);
        if (tokenSim >= 65) return tokenSim.setScale(2);

        Decimal charSim = levenshteinSimilarityPercent(normA, normB);
        Decimal best = (tokenSim > charSim) ? tokenSim : charSim;
        return best.setScale(2);
    }

    // Intersection count (with frequency) / maxWords * 100
    private static Decimal tokenOverlapPercent(List<String> a, List<String> b) {
        if (a.isEmpty() || b.isEmpty()) return 0;

        Map<String, Integer> ca = wordCount(a);
        Map<String, Integer> cb = wordCount(b);

        Integer inter = 0;
        for (String k : ca.keySet()) {
            if (cb.containsKey(k)) inter += Math.min(ca.get(k), cb.get(k));
        }

        Integer maxWords = Math.max(a.size(), b.size());
        if (maxWords == 0) return 0;

        Decimal dInter = Decimal.valueOf(String.valueOf(inter));
        Decimal dMax = Decimal.valueOf(String.valueOf(maxWords));
        return (dInter / dMax) * 100;
    }

    // Levenshtein similarity => (1 - dist/maxLen)*100
    private static Decimal levenshteinSimilarityPercent(String a, String b) {
        if (String.isBlank(a) || String.isBlank(b)) return 0;

        String s1 = a.replaceAll('\\s+', ' ').trim();
        String s2 = b.replaceAll('\\s+', ' ').trim();

        Integer maxLen = Math.max(s1.length(), s2.length());
        if (maxLen == 0) return 100;

        // guard
        if (maxLen > 300) return 0;

        Integer dist = levenshteinDistance(s1, s2);
        Decimal dDist = Decimal.valueOf(String.valueOf(dist));
        Decimal dMax = Decimal.valueOf(String.valueOf(maxLen));

        Decimal sim = (1 - (dDist / dMax)) * 100;
        if (sim < 0) sim = 0;
        return sim;
    }

    // Iterative DP (swap lists - less allocations)
    private static Integer levenshteinDistance(String s, String t) {
        Integer n = s.length();
        Integer m = t.length();

        if (n == 0) return m;
        if (m == 0) return n;

        List<Integer> prev = new List<Integer>();
        List<Integer> curr = new List<Integer>();

        for (Integer j = 0; j <= m; j++) prev.add(j);

        for (Integer i = 1; i <= n; i++) {
            curr.clear();
            curr.add(i);

            for (Integer j = 1; j <= m; j++) {
                Integer cost = (s.substring(i - 1, i) == t.substring(j - 1, j)) ? 0 : 1;

                Integer del = prev[j] + 1;
                Integer ins = curr[j - 1] + 1;
                Integer sub = prev[j - 1] + cost;

                curr.add(Math.min(del, Math.min(ins, sub)));
            }

            // swap: prev = curr
            prev.clear();
            prev.addAll(curr);
        }
        return prev[m];
    }

    // ------------------- Normalization -------------------
    private static String normalize(String address) {
        if (String.isBlank(address)) return '';

        String a = address.toLowerCase();

        // remove punctuation -> spaces
        a = a.replaceAll('[^a-z0-9\\s]', ' ');

        // remove ordinal suffixes: 1st -> 1, 22nd -> 22
        a = a.replaceAll('\\b(\\d+)(st|nd|rd|th)\\b', '$1');

        a = replaceAbbreviations(a);

        // collapse spaces
        a = a.replaceAll('\\s+', ' ').trim();
        return a;
    }

    private static String replaceAbbreviations(String s) {
        Map<String, String> abbr = new Map<String, String>{
            'st'   => 'street',
            'rd'   => 'road',
            'ave'  => 'avenue',
            'blvd' => 'boulevard',
            'ln'   => 'lane',
            'dr'   => 'drive',
            'ct'   => 'court',
            'hwy'  => 'highway',
            'sec'  => 'sector',
            'apt'  => 'apartment',
            'bldg' => 'building',
            'fl'   => 'floor',
            'dist' => 'district',
            'po'   => 'postoffice'
        };

        for (String k : abbr.keySet()) {
            s = s.replaceAll('\\b' + k + '\\b', abbr.get(k));
        }
        return s;
    }
}