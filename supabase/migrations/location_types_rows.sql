INSERT INTO "public"."location_types" ("id", "created_at", "name", "category") VALUES
    ('80d51c51-f447-4c61-bffe-a0d407854394', now(), 'Family, Kids & Education', 'business'),
    ('5a7ee5d3-69ce-4b25-945a-c7bf79aee7d8', now(), 'Nightlife & Entertainment', 'business'),
    ('307d8d0f-bcea-438b-9d86-c81e604d7300', now(), 'Travel, Tourism & Lodging', 'business'),
    ('7248ec49-6560-4dc5-86c4-9fbedceed656', now(), 'Outdoor & Recreation', 'business'),
    ('6f92d684-f887-49fe-9522-14a422428636', now(), 'Professional & Creative Services', 'business'),
    ('2572760d-f6c9-45cc-9d20-854bb4260cb1', now(), 'Community, Nonprofit & Public Services', 'business'),
    ('6327705b-afa5-4aaf-bf3d-f21a3c2a36fc', now(), 'Food & Drink', 'business'),
    ('8ffaa27f-7aa4-44bc-8dbd-5876e3ab418e', now(), 'Retail & Shopping', 'business'),
    ('2a98b5ed-a1e3-4c16-ab6d-a51864c56612', now(), 'Home & Lifestyle Services', 'business'),
    ('cd5a98b3-4a16-4d0d-b52f-10893d19cde6', now(), 'Attractions & Activities', 'business'),
    ('5a716a6d-cf61-4d8a-a7be-b347c4287216', now(), 'Arts & Culture', 'business'),
    ('285b57f1-a278-426e-b149-3f7f1b036cab', now(), 'Health, Beauty & Wellness', 'business')
ON CONFLICT (name, category) DO NOTHING;


INSERT INTO "public"."location_tags" ("id","label","type_id") VALUES
    (gen_random_uuid(), 'Artist Studios & Open-Work Spaces', '5a716a6d-cf61-4d8a-a7be-b347c4287216'),
    (gen_random_uuid(), 'Cultural Festivals', '5a716a6d-cf61-4d8a-a7be-b347c4287216'),
    (gen_random_uuid(), 'Fringe & Experimental Arts Spaces', '5a716a6d-cf61-4d8a-a7be-b347c4287216'),
    (gen_random_uuid(), 'Local Art Fairs & Gallery Districts', '5a716a6d-cf61-4d8a-a7be-b347c4287216'),
    (gen_random_uuid(), 'Performing Arts Venues', '5a716a6d-cf61-4d8a-a7be-b347c4287216'),
    (gen_random_uuid(), 'Queer Craft Zine & Comic Creators', '5a716a6d-cf61-4d8a-a7be-b347c4287216'),
    (()gen_random_uuid, 'Queer Film & Independent Cinemas', '5a716a6d-cf61-4d8a-a7be-b347c4287216'),
    (gen_random_uuid(), 'Queer Literary Spaces & Poetry Venues', '5a716a6d-cf61-4d8a-a7be-b347c4287216'),
    (gen_random_uuid(), 'Queer Playwrights Actors & Ensembles', '5a716a6d-cf61-4d8a-a7be-b347c4287216'),
    (gen_random_uuid(), 'Musicians, Dancers & Visual Artists & Performers', '5a716a6d-cf61-4d8a-a7be-b347c4287216'),
    (gen_random_uuid(), 'Queer Muralists & Street Artists', '5a716a6d-cf61-4d8a-a7be-b347c4287216'),
    (gen_random_uuid(), 'Queer Podcasts & Media Productions', '5a716a6d-cf61-4d8a-a7be-b347c4287216'),
    (gen_random_uuid(), 'Queer Fashion Designers & Costume Makers', '5a716a6d-cf61-4d8a-a7be-b347c4287216')
ON CONFLICT (type_id, label) DO NOTHING;


INSERT INTO "public"."location_tags" ("id","label","type_id") VALUES
    (gen_random_uuid(), 'Cleaning Services', '2a98b5ed-a1e3-4c16-ab6d-a51864c56612'),
    (gen_random_uuid(), 'Gardening & Landscaping', '2a98b5ed-a1e3-4c16-ab6d-a51864c56612'),
    (gen_random_uuid(), 'Movers & Hauling Services', '2a98b5ed-a1e3-4c16-ab6d-a51864c56612'),
    (gen_random_uuid(), 'Real Estate Agents & Queer-Affirming Realtors', '2a98b5ed-a1e3-4c16-ab6d-a51864c56612'),
    (gen_random_uuid(), 'Repair Services', '2a98b5ed-a1e3-4c16-ab6d-a51864c56612'),
    (gen_random_uuid(), 'Interior Design & Staging Services', '2a98b5ed-a1e3-4c16-ab6d-a51864c56612'),
    (gen_random_uuid(), 'Pet Care & Veterinary Services', '2a98b5ed-a1e3-4c16-ab6d-a51864c56612'),
    (gen_random_uuid(), 'Wedding & Event Planning', '2a98b5ed-a1e3-4c16-ab6d-a51864c56612'),
    (gen_random_uuid(), 'Queer-Affirming Financial Advisors', '2a98b5ed-a1e3-4c16-ab6d-a51864c56612')
ON CONFLICT (type_id, label) DO NOTHING;


INSERT INTO "public"."location_tags" ("id","label","type_id") VALUES
    (gen_random_uuid(), 'Architectural Sites & City Icons', 'cd5a98b3-4a16-4d0d-b52f-10893d19cde6'),
    (gen_random_uuid(), 'Botanical Gardens & Conservatories', 'cd5a98b3-4a16-4d0d-b52f-10893d19cde6'),
    (gen_random_uuid(), 'Community Cultural Centers', 'cd5a98b3-4a16-4d0d-b52f-10893d19cde6'),
    (gen_random_uuid(), 'Interactive Science & Discovery Centers', 'cd5a98b3-4a16-4d0d-b52f-10893d19cde6'),
    (gen_random_uuid(), 'LGBTQ+ Heritage Walks & Monuments', 'cd5a98b3-4a16-4d0d-b52f-10893d19cde6'),
    (gen_random_uuid(), 'LGBTQ+ Heritage Tour Operators', 'cd5a98b3-4a16-4d0d-b52f-10893d19cde6'),
    (gen_random_uuid(), 'Museums', 'cd5a98b3-4a16-4d0d-b52f-10893d19cde6'),
    (gen_random_uuid(), 'Murals & Queer Street Art', 'cd5a98b3-4a16-4d0d-b52f-10893d19cde6'),
    (gen_random_uuid(), 'Observatories & Planetariums', 'cd5a98b3-4a16-4d0d-b52f-10893d19cde6'),
    (gen_random_uuid(), 'Public Art Installations & Sculptures', 'cd5a98b3-4a16-4d0d-b52f-10893d19cde6'),
    (gen_random_uuid(), 'Queer Landmarks & Historic Sites', 'cd5a98b3-4a16-4d0d-b52f-10893d19cde6'),
    (gen_random_uuid(), 'Zoos & Aquariums', 'cd5a98b3-4a16-4d0d-b52f-10893d19cde6'),
    (gen_random_uuid(), 'Escape Rooms & Immersive Experiences', 'cd5a98b3-4a16-4d0d-b52f-10893d19cde6'),
    (gen_random_uuid(), 'Queer Tours & Walking Tours', 'cd5a98b3-4a16-4d0d-b52f-10893d19cde6'),
    (gen_random_uuid(), 'Arcades & Entertainment Venues', 'cd5a98b3-4a16-4d0d-b52f-10893d19cde6')
ON CONFLICT (type_id, label) DO NOTHING;

INSERT INTO "public"."location_tags" ("id","label","type_id") VALUES
    (gen_random_uuid(), 'Dance Clubs & Queer Nights', '5a7ee5d3-69ce-4b25-945a-c7bf79aee7d8'),
    (gen_random_uuid(), 'Drag & Cabaret Venues & Productions', '5a7ee5d3-69ce-4b25-945a-c7bf79aee7d8'),
    (gen_random_uuid(), 'Pageant Production Companies', '5a7ee5d3-69ce-4b25-945a-c7bf79aee7d8'),
    (gen_random_uuid(), 'Boat & Cruise Party Operators', '5a7ee5d3-69ce-4b25-945a-c7bf79aee7d8'),
    (gen_random_uuid(), 'Fetish Leather & Underground Venues', '5a7ee5d3-69ce-4b25-945a-c7bf79aee7d8'),
    (gen_random_uuid(), 'Immersive Experience Venues', '5a7ee5d3-69ce-4b25-945a-c7bf79aee7d8'),
    (gen_random_uuid(), 'Indie Theaters & Performance Spaces', '5a7ee5d3-69ce-4b25-945a-c7bf79aee7d8'),
    (gen_random_uuid(), 'Karaoke Trivia & Game Night Venues', '5a7ee5d3-69ce-4b25-945a-c7bf79aee7d8'),
    (gen_random_uuid(), 'Live Music Venues', '5a7ee5d3-69ce-4b25-945a-c7bf79aee7d8'),
    (gen_random_uuid(), 'Pride & Festival Party Venues', '5a7ee5d3-69ce-4b25-945a-c7bf79aee7d8'),
    (gen_random_uuid(), 'Queer Bars & Taverns', '5a7ee5d3-69ce-4b25-945a-c7bf79aee7d8'),
    (gen_random_uuid(), 'Queer Comedy Clubs & Open Mic Venues', '5a7ee5d3-69ce-4b25-945a-c7bf79aee7d8'),
    (gen_random_uuid(), 'Queer DJ & Rave Promoters', '5a7ee5d3-69ce-4b25-945a-c7bf79aee7d8'),
    (gen_random_uuid(), 'Sober & Low-Sensory Nightlife Venues', '5a7ee5d3-69ce-4b25-945a-c7bf79aee7d8'),
    (gen_random_uuid(), 'Burlesque Venues & Producers', '5a7ee5d3-69ce-4b25-945a-c7bf79aee7d8'),
    (gen_random_uuid(), 'Bathhouses & Queer Social Clubs', '5a7ee5d3-69ce-4b25-945a-c7bf79aee7d8'),
    (gen_random_uuid(), 'Day Clubs & Pool Venues', '5a7ee5d3-69ce-4b25-945a-c7bf79aee7d8')
ON CONFLICT (type_id, label) DO NOTHING;

INSERT INTO "public"."location_tags" ("id","label","type_id") VALUES
    (gen_random_uuid(), 'Queer Community Events & Venues', '2572760d-f6c9-45cc-9d20-854bb4260cb1'),
    (gen_random_uuid(), 'Cultural Offices', '2572760d-f6c9-45cc-9d20-854bb4260cb1'),
    (gen_random_uuid(), 'Legal Aid & LGBTQ+ Rights Firms', '2572760d-f6c9-45cc-9d20-854bb4260cb1'),
    (gen_random_uuid(), 'Local Government LGBTQ+ Liaisons', '2572760d-f6c9-45cc-9d20-854bb4260cb1'),
    (gen_random_uuid(), 'Mediation & Conflict Resolution Services', '2572760d-f6c9-45cc-9d20-854bb4260cb1'),
    (gen_random_uuid(), 'Private Security & Community Safety Firms', '2572760d-f6c9-45cc-9d20-854bb4260cb1'),
    (gen_random_uuid(), 'Professional Training & Certification Providers', '2572760d-f6c9-45cc-9d20-854bb4260cb1'),
    (gen_random_uuid(), 'LGBTQ+ Nonprofits & Advocacy Organizations', '2572760d-f6c9-45cc-9d20-854bb4260cb1'),
    (gen_random_uuid(), 'Mutual Aid Networks', '2572760d-f6c9-45cc-9d20-854bb4260cb1'),
    (gen_random_uuid(), 'Crisis Hotlines & Support Lines', '2572760d-f6c9-45cc-9d20-854bb4260cb1'),
    (gen_random_uuid(), 'Trans-Specific Support Organizations', '2572760d-f6c9-45cc-9d20-854bb4260cb1'),
    (gen_random_uuid(), 'HIV/AIDS Service Organizations', '2572760d-f6c9-45cc-9d20-854bb4260cb1'),
    (gen_random_uuid(), 'Queer Youth Organizations', '2572760d-f6c9-45cc-9d20-854bb4260cb1'),
    (gen_random_uuid(), 'Queer Elder Care Services', '2572760d-f6c9-45cc-9d20-854bb4260cb1'),
    (gen_random_uuid(), 'Immigration & Refugee Support Services', '2572760d-f6c9-45cc-9d20-854bb4260cb1'),
    (gen_random_uuid(), 'Domestic Violence & Safety Services', '2572760d-f6c9-45cc-9d20-854bb4260cb1')
ON CONFLICT (type_id, label) DO NOTHING;

INSERT INTO "public"."location_tags" ("id","label","type_id") VALUES
    (gen_random_uuid(), 'Community Centers & Drop-In Centers', '7248ec49-6560-4dc5-86c4-9fbedceed656'),
    (gen_random_uuid(), 'LGBTQ+ Camping & Outdoor Retreat Sites', '7248ec49-6560-4dc5-86c4-9fbedceed656'),
    (gen_random_uuid(), 'Public Pools & Recreation Centers', '7248ec49-6560-4dc5-86c4-9fbedceed656'),
    (gen_random_uuid(), 'Queer-Friendly Outdoor Adventure Groups', '7248ec49-6560-4dc5-86c4-9fbedceed656'),
    (gen_random_uuid(), 'Boat Tours & Cruises', '7248ec49-6560-4dc5-86c4-9fbedceed656'),
    (gen_random_uuid(), 'Race & Event Organizers', '7248ec49-6560-4dc5-86c4-9fbedceed656'),
    (gen_random_uuid(), 'Queer Sports Leagues & Teams', '7248ec49-6560-4dc5-86c4-9fbedceed656'),
    (gen_random_uuid(), 'Swimming Clubs & Aquatic Centers', '7248ec49-6560-4dc5-86c4-9fbedceed656'),
    (gen_random_uuid(), 'Roller Rinks & Skating Spaces', '7248ec49-6560-4dc5-86c4-9fbedceed656'),
    (gen_random_uuid(), 'Rock Climbing & Bouldering Gyms', '7248ec49-6560-4dc5-86c4-9fbedceed656'),
    (gen_random_uuid(), 'Nature Reserves & Wildlife Areas', '7248ec49-6560-4dc5-86c4-9fbedceed656'),
    (gen_random_uuid(), 'Parks & Green Spaces', '7248ec49-6560-4dc5-86c4-9fbedceed656'),
    (gen_random_uuid(), 'Bike Paths & Cycling Routes', '7248ec49-6560-4dc5-86c4-9fbedceed656'),
    (gen_random_uuid(), 'Dog Parks & Pet-Friendly Spaces', '7248ec49-6560-4dc5-86c4-9fbedceed656'),
    (gen_random_uuid(), 'Trailheads & Hiking Routes', '7248ec49-6560-4dc5-86c4-9fbedceed656'),
    (gen_random_uuid(), 'Waterfronts Beaches & Piers', '7248ec49-6560-4dc5-86c4-9fbedceed656')
ON CONFLICT (type_id, label) DO NOTHING;

INSERT INTO "public"."location_tags" ("id","label","type_id") VALUES
    (gen_random_uuid(), 'Family Resource Centers','80d51c51-f447-4c61-bffe-a0d407854394'),
    (gen_random_uuid(), 'Inclusive Clothing & Gift Boutiques','80d51c51-f447-4c61-bffe-a0d407854394'),
    (gen_random_uuid(), 'Kid-Inclusive Fitness & Recreation Studios','80d51c51-f447-4c61-bffe-a0d407854394'),
    (gen_random_uuid(), 'LGBTQ+ Event Planners','80d51c51-f447-4c61-bffe-a0d407854394'),
    (gen_random_uuid(), 'LGBTQ+ Family Photographers','80d51c51-f447-4c61-bffe-a0d407854394'),
    (gen_random_uuid(), 'LGBTQ+ Parenting Programs','80d51c51-f447-4c61-bffe-a0d407854394'),
    (gen_random_uuid(), 'Queer-Friendly Arcades Mini Golf & Play Spaces','80d51c51-f447-4c61-bffe-a0d407854394'),
    (gen_random_uuid(), 'Queer-Owned Childcare & Babysitting','80d51c51-f447-4c61-bffe-a0d407854394'),
    (gen_random_uuid(), 'Queer-Owned Toy & Book Shops','80d51c51-f447-4c61-bffe-a0d407854394'),
    (gen_random_uuid(), 'Tutoring Centers & Educational Supply Shops','80d51c51-f447-4c61-bffe-a0d407854394'),
    (gen_random_uuid(), 'Youth Arts & Creative Workshops','80d51c51-f447-4c61-bffe-a0d407854394'),
    (gen_random_uuid(), 'Queer-Affirming Schools & Academic Programs','80d51c51-f447-4c61-bffe-a0d407854394'),
    (gen_random_uuid(), 'Queer Summer Camps','80d51c51-f447-4c61-bffe-a0d407854394')
ON CONFLICT (type_id, label) DO NOTHING;


INSERT INTO "public"."location_tags" ("id","label","type_id") VALUES
    (gen_random_uuid(), 'Networking & Mentorship','6f92d684-f887-49fe-9522-14a422428636'),
    (gen_random_uuid(), 'Financial Services','6f92d684-f887-49fe-9522-14a422428636'),
    (gen_random_uuid(), 'Co-Working & Office Spaces','6f92d684-f887-49fe-9522-14a422428636'),
    (gen_random_uuid(), 'Design Studios','6f92d684-f887-49fe-9522-14a422428636'),
    (gen_random_uuid(), 'Film Stage & Event Production','6f92d684-f887-49fe-9522-14a422428636'),
    (gen_random_uuid(), 'HR DEI & Organizational Consulting','6f92d684-f887-49fe-9522-14a422428636'),
    (gen_random_uuid(), 'Legal & Accounting Services','6f92d684-f887-49fe-9522-14a422428636'),
    (gen_random_uuid(), 'Marketing Branding & PR Agencies','6f92d684-f887-49fe-9522-14a422428636'),
    (gen_random_uuid(), 'Photography Videography & Creative Studios','6f92d684-f887-49fe-9522-14a422428636'),
    (gen_random_uuid(), 'Print & Production Shops','6f92d684-f887-49fe-9522-14a422428636'),
    (gen_random_uuid(), 'Web Development & Tech Firms','6f92d684-f887-49fe-9522-14a422428636'),
    (gen_random_uuid(), 'Grant Writing & Fundraising Consultants','6f92d684-f887-49fe-9522-14a422428636'),
    (gen_random_uuid(), 'Nonprofit Consulting & Development','6f92d684-f887-49fe-9522-14a422428636'),
    (gen_random_uuid(), 'Queer Journalists & Media Consultants','6f92d684-f887-49fe-9522-14a422428636'),
    (gen_random_uuid(), 'Translation & Interpretation Services','6f92d684-f887-49fe-9522-14a422428636'),
    (gen_random_uuid(), 'Event DJ & Entertainment Booking','6f92d684-f887-49fe-9522-14a422428636')
ON CONFLICT (type_id, label) DO NOTHING;


INSERT INTO "public"."location_tags" ("id","label","type_id") VALUES
    (gen_random_uuid(), 'Bakeries & Dessert Shops','6327705b-afa5-4aaf-bf3d-f21a3c2a36fc'),
    (gen_random_uuid(), 'Breweries Pubs & Lounges','6327705b-afa5-4aaf-bf3d-f21a3c2a36fc'),
    (gen_random_uuid(), 'Cocktail Bars & Lounges','6327705b-afa5-4aaf-bf3d-f21a3c2a36fc'),
    (gen_random_uuid(), 'Food Co-ops & Community Kitchens','6327705b-afa5-4aaf-bf3d-f21a3c2a36fc'),
    (gen_random_uuid(), 'Food Trucks & Pop-Ups','6327705b-afa5-4aaf-bf3d-f21a3c2a36fc'),
    (gen_random_uuid(), 'Queer Cafés & Coffeehouses','6327705b-afa5-4aaf-bf3d-f21a3c2a36fc'),
    (gen_random_uuid(), 'Queer Caterers & Private Chefs','6327705b-afa5-4aaf-bf3d-f21a3c2a36fc'),
    (gen_random_uuid(), 'Queer-Owned Grocery & Market Stalls','6327705b-afa5-4aaf-bf3d-f21a3c2a36fc'),
    (gen_random_uuid(), 'Queer-Owned Restaurants & Diners','6327705b-afa5-4aaf-bf3d-f21a3c2a36fc'),
    (gen_random_uuid(), 'Specialty Food Shops','6327705b-afa5-4aaf-bf3d-f21a3c2a36fc'),
    (gen_random_uuid(), 'Vegan & Vegetarian Spots','6327705b-afa5-4aaf-bf3d-f21a3c2a36fc'),
    (gen_random_uuid(), 'Wine Bars & Tasting Rooms','6327705b-afa5-4aaf-bf3d-f21a3c2a36fc'),
    (gen_random_uuid(), 'Clubs & Clubhouses','6327705b-afa5-4aaf-bf3d-f21a3c2a36fc'),
    (gen_random_uuid(), 'Queer-Owned Food Markets & Farmers Markets','6327705b-afa5-4aaf-bf3d-f21a3c2a36fc'),
    (gen_random_uuid(), 'Juice Bars & Health-Focused Cafés','6327705b-afa5-4aaf-bf3d-f21a3c2a36fc'),
    (gen_random_uuid(), 'Sober Bars & Mocktail Lounges','6327705b-afa5-4aaf-bf3d-f21a3c2a36fc')
ON CONFLICT (type_id, label) DO NOTHING;


INSERT INTO "public"."location_tags" ("id","label","type_id") VALUES
    (gen_random_uuid(), 'Adult Intimacy & Toy Shops','8ffaa27f-7aa4-44bc-8dbd-5876e3ab418e'),
    (gen_random_uuid(), 'Art Galleries & Queer Artist Collectives','8ffaa27f-7aa4-44bc-8dbd-5876e3ab418e'),
    (gen_random_uuid(), 'Craft Supply & Stationery Stores','8ffaa27f-7aa4-44bc-8dbd-5876e3ab418e'),
    (gen_random_uuid(), 'Fashion Boutiques & Apparel Shops','8ffaa27f-7aa4-44bc-8dbd-5876e3ab418e'),
    (gen_random_uuid(), 'Home Goods & Décor Shops','8ffaa27f-7aa4-44bc-8dbd-5876e3ab418e'),
    (gen_random_uuid(), 'Home Décor & Furniture Shops','8ffaa27f-7aa4-44bc-8dbd-5876e3ab418e'),
    (gen_random_uuid(), 'Jewelry & Accessories Shops','8ffaa27f-7aa4-44bc-8dbd-5876e3ab418e'),
    (gen_random_uuid(), 'Makers Markets & Pop-Up Shops','8ffaa27f-7aa4-44bc-8dbd-5876e3ab418e'),
    (gen_random_uuid(), 'Plant Shops & LGBTQ+ Florists','8ffaa27f-7aa4-44bc-8dbd-5876e3ab418e'),
    (gen_random_uuid(), 'Queer-Owned Bookstores','8ffaa27f-7aa4-44bc-8dbd-5876e3ab418e'),
    (gen_random_uuid(), 'Record & Music Shops','8ffaa27f-7aa4-44bc-8dbd-5876e3ab418e'),
    (gen_random_uuid(), 'Queer Gift Shops & Novelty Stores','8ffaa27f-7aa4-44bc-8dbd-5876e3ab418e'),
    (gen_random_uuid(), 'Thrift Vintage & Consignment Stores','8ffaa27f-7aa4-44bc-8dbd-5876e3ab418e'),
    (gen_random_uuid(), 'Pride Merchandise & Apparel','8ffaa27f-7aa4-44bc-8dbd-5876e3ab418e'),
    (gen_random_uuid(), 'Sex-Positive & Wellness Shops','8ffaa27f-7aa4-44bc-8dbd-5876e3ab418e'),
    (gen_random_uuid(), 'Queer-Owned Online Shops & Etsy Sellers','8ffaa27f-7aa4-44bc-8dbd-5876e3ab418e')
ON CONFLICT (type_id, label) DO NOTHING;


INSERT INTO "public"."location_tags" ("id","label","type_id") VALUES
    (gen_random_uuid(), 'Barbershops & Grooming Studios','285b57f1-a278-426e-b149-3f7f1b036cab'),
    (gen_random_uuid(), 'Holistic & Alternative Medicine','285b57f1-a278-426e-b149-3f7f1b036cab'),
    (gen_random_uuid(), 'LGBTQ+ Health Clinics & Practices','285b57f1-a278-426e-b149-3f7f1b036cab'),
    (gen_random_uuid(), 'Massage & Bodywork Practices','285b57f1-a278-426e-b149-3f7f1b036cab'),
    (gen_random_uuid(), 'Meditation & Mindfulness Centers','285b57f1-a278-426e-b149-3f7f1b036cab'),
    (gen_random_uuid(), 'Mental Health Providers','285b57f1-a278-426e-b149-3f7f1b036cab'),
    (gen_random_uuid(), 'Queer-Affirming Spas & Salons','285b57f1-a278-426e-b149-3f7f1b036cab'),
    (gen_random_uuid(), 'Queer-Friendly Gyms','285b57f1-a278-426e-b149-3f7f1b036cab'),
    (gen_random_uuid(), 'Sexual Health & Wellness Clinics','285b57f1-a278-426e-b149-3f7f1b036cab'),
    (gen_random_uuid(), 'Tattoo & Piercing Studios','285b57f1-a278-426e-b149-3f7f1b036cab'),
    (gen_random_uuid(), 'Voice Coaching & Gender-Affirming Services','285b57f1-a278-426e-b149-3f7f1b036cab'),
    (gen_random_uuid(), 'Yoga Dance & Fitness Studios','285b57f1-a278-426e-b149-3f7f1b036cab'),
    (gen_random_uuid(), 'Trans Healthcare Providers','285b57f1-a278-426e-b149-3f7f1b036cab'),
    (gen_random_uuid(), 'Queer Midwives & Birth Workers','285b57f1-a278-426e-b149-3f7f1b036cab'),
    (gen_random_uuid(), 'Reproductive Health Services','285b57f1-a278-426e-b149-3f7f1b036cab'),
    (gen_random_uuid(), 'Nutrition & Dietitian Services','285b57f1-a278-426e-b149-3f7f1b036cab'),
    (gen_random_uuid(), 'Acupuncture & Eastern Medicine','285b57f1-a278-426e-b149-3f7f1b036cab'),
    (gen_random_uuid(), 'Gender-Affirming Surgery Providers','285b57f1-a278-426e-b149-3f7f1b036cab'),
    (gen_random_uuid(), 'Queer-Affirming Dentists & Dental Practices','285b57f1-a278-426e-b149-3f7f1b036cab')
ON CONFLICT (type_id, label) DO NOTHING;


INSERT INTO "public"."location_tags" ("id","label","type_id") VALUES
    (gen_random_uuid(), 'Accessible Transport Providers','307d8d0f-bcea-438b-9d86-c81e604d7300'),
    (gen_random_uuid(), 'Airport Transfers & Rideshare Alternatives','307d8d0f-bcea-438b-9d86-c81e604d7300'),
    (gen_random_uuid(), 'B&Bs & Guesthouses','307d8d0f-bcea-438b-9d86-c81e604d7300'),
    (gen_random_uuid(), 'Bike Rentals Scooters & Micro-Mobility','307d8d0f-bcea-438b-9d86-c81e604d7300'),
    (gen_random_uuid(), 'Boutique & Luxury Stays','307d8d0f-bcea-438b-9d86-c81e604d7300'),
    (gen_random_uuid(), 'LGBTQ+ Campgrounds & Cabins','307d8d0f-bcea-438b-9d86-c81e604d7300'),
    (gen_random_uuid(), 'LGBTQ+ Shuttle Services','307d8d0f-bcea-438b-9d86-c81e604d7300'),
    (gen_random_uuid(), 'LGBTQ+ Tour Operators','307d8d0f-bcea-438b-9d86-c81e604d7300'),
    (gen_random_uuid(), 'LGBTQ+ Travel Media','307d8d0f-bcea-438b-9d86-c81e604d7300'),
    (gen_random_uuid(), 'Queer City Guides & Local Hosts','307d8d0f-bcea-438b-9d86-c81e604d7300'),
    (gen_random_uuid(), 'Queer-Owned Hotels & Hostels','307d8d0f-bcea-438b-9d86-c81e604d7300'),
    (gen_random_uuid(), 'Queer-Owned Transportation','307d8d0f-bcea-438b-9d86-c81e604d7300'),
    (gen_random_uuid(), 'Pride & Festival Travel Packages','307d8d0f-bcea-438b-9d86-c81e604d7300'),
    (gen_random_uuid(), 'Short-Term Rentals','307d8d0f-bcea-438b-9d86-c81e604d7300'),
    (gen_random_uuid(), 'Visitor Centers & Tourism Boards','307d8d0f-bcea-438b-9d86-c81e604d7300'),
    (gen_random_uuid(), 'Queer Cruise Lines & Packages','307d8d0f-bcea-438b-9d86-c81e604d7300'),
    (gen_random_uuid(), 'LGBTQ+ Destination Wedding Planners','307d8d0f-bcea-438b-9d86-c81e604d7300'),
    (gen_random_uuid(), 'Queer Retreat Centers','307d8d0f-bcea-438b-9d86-c81e604d7300'),
    (gen_random_uuid(), 'LGBTQ+ Travel Insurance Providers','307d8d0f-bcea-438b-9d86-c81e604d7300'),
    (gen_random_uuid(), 'Pet-Friendly LGBTQ+ Accommodations','307d8d0f-bcea-438b-9d86-c81e604d7300')
ON CONFLICT (type_id, label) DO NOTHING;

INSERT INTO "public"."location_types" ("id", "created_at", "name", "category") VALUES
    (gen_random_uuid(), now(), 'Community & Advocacy', 'resource'),
    (gen_random_uuid(), now(), 'Health & Wellness', 'resource'),
    (gen_random_uuid(), now(), 'Crisis & Safety Support', 'resource'),
    (gen_random_uuid(), now(), 'Faith & Spirituality', 'resource'),
    (gen_random_uuid(), now(), 'Legal & Rights Support', 'resource'),
    (gen_random_uuid(), now(), 'Education & Learning', 'resource'),
    (gen_random_uuid(), now(), 'Social Connection & Community Groups', 'resource'),
    (gen_random_uuid(), now(), 'Practical Help & Services', 'resource')
ON CONFLICT (name, category) DO NOTHING;

INSERT INTO "public"."location_tags" ("id","label","type_id") VALUES
    (gen_random_uuid(), 'LGBTQ+ Community Centers', '5c670acc-bc95-41ca-93d7-e8e444ea8cbb'),
    (gen_random_uuid(), 'Pride & Advocacy Organizations', '5c670acc-bc95-41ca-93d7-e8e444ea8cbb'),
    (gen_random_uuid(), 'Youth & Student Programs', '5c670acc-bc95-41ca-93d7-e8e444ea8cbb'),
    (gen_random_uuid(), 'Senior & Elder Queer Programs', '5c670acc-bc95-41ca-93d7-e8e444ea8cbb'),
    (gen_random_uuid(), 'QTPOC Collectives', '5c670acc-bc95-41ca-93d7-e8e444ea8cbb'),
    (gen_random_uuid(), 'Trans & Nonbinary Networks', '5c670acc-bc95-41ca-93d7-e8e444ea8cbb'),
    (gen_random_uuid(), 'Lesbian & WLW Groups', '5c670acc-bc95-41ca-93d7-e8e444ea8cbb'),
    (gen_random_uuid(), 'Gay & MLM Groups', '5c670acc-bc95-41ca-93d7-e8e444ea8cbb'),
    (gen_random_uuid(), 'Bisexual & Pansexual Networks', '5c670acc-bc95-41ca-93d7-e8e444ea8cbb'),
    (gen_random_uuid(), 'Asexual & Aromantic Networks', '5c670acc-bc95-41ca-93d7-e8e444ea8cbb'),
    (gen_random_uuid(), 'Intersex Community Organizations', '5c670acc-bc95-41ca-93d7-e8e444ea8cbb'),
    (gen_random_uuid(), 'Two-Spirit & Indigenous Spaces', '5c670acc-bc95-41ca-93d7-e8e444ea8cbb'),
    (gen_random_uuid(), 'Queer Disability & Disability Justice Networks', '5c670acc-bc95-41ca-93d7-e8e444ea8cbb'),
    (gen_random_uuid(), 'Queer Neurodivergent Groups', '5c670acc-bc95-41ca-93d7-e8e444ea8cbb'),
    (gen_random_uuid(), 'Immigrant & Refugee Queer Support', '5c670acc-bc95-41ca-93d7-e8e444ea8cbb'),
    (gen_random_uuid(), 'Queer Incarcerated & Reentry Support', '5c670acc-bc95-41ca-93d7-e8e444ea8cbb')
ON CONFLICT (type_id, label) DO NOTHING;

INSERT INTO "public"."location_tags" ("id","label","type_id") VALUES
    (gen_random_uuid(), 'Crisis Hotlines', '0df019d3-12d3-45b9-971b-f0839b0a4abf'),
    (gen_random_uuid(), 'Suicide Prevention Services', '0df019d3-12d3-45b9-971b-f0839b0a4abf'),
    (gen_random_uuid(), 'Sexual Assault & Survivor Support', '0df019d3-12d3-45b9-971b-f0839b0a4abf'),
    (gen_random_uuid(), 'Anti-Violence Programs', '0df019d3-12d3-45b9-971b-f0839b0a4abf'),
    (gen_random_uuid(), 'Domestic Violence Shelters', '0df019d3-12d3-45b9-971b-f0839b0a4abf'),
    (gen_random_uuid(), 'Safety Planning Resources', '0df019d3-12d3-45b9-971b-f0839b0a4abf'),
    (gen_random_uuid(), 'Trans-Specific Crisis Support', '0df019d3-12d3-45b9-971b-f0839b0a4abf'),
    (gen_random_uuid(), 'Homeless Queer Youth Programs', '0df019d3-12d3-45b9-971b-f0839b0a4abf'),
    (gen_random_uuid(), 'Family & Parent Acceptance Support', '0df019d3-12d3-45b9-971b-f0839b0a4abf'),
    (gen_random_uuid(), 'Emergency Housing & Shelter Access', '0df019d3-12d3-45b9-971b-f0839b0a4abf')
ON CONFLICT (type_id, label) DO NOTHING;

INSERT INTO "public"."location_tags" ("id","label","type_id") VALUES
    (gen_random_uuid(), 'Mental Health Counseling & Therapy', '57691c07-ed39-4341-b291-eab27ba2d4da'),
    (gen_random_uuid(), 'Peer Support Groups', '57691c07-ed39-4341-b291-eab27ba2d4da'),
    (gen_random_uuid(), 'HIV Testing & PrEP Access', '57691c07-ed39-4341-b291-eab27ba2d4da'),
    (gen_random_uuid(), 'STI Clinics & Sexual Health Services', '57691c07-ed39-4341-b291-eab27ba2d4da'),
    (gen_random_uuid(), 'Gender-Affirming Care', '57691c07-ed39-4341-b291-eab27ba2d4da'),
    (gen_random_uuid(), 'Trans Healthcare Navigation', '57691c07-ed39-4341-b291-eab27ba2d4da'),
    (gen_random_uuid(), 'Reproductive Health Services', '57691c07-ed39-4341-b291-eab27ba2d4da'),
    (gen_random_uuid(), 'Recovery & Harm Reduction Programs', '57691c07-ed39-4341-b291-eab27ba2d4da'),
    (gen_random_uuid(), 'Chronic Illness & Pain Support', '57691c07-ed39-4341-b291-eab27ba2d4da'),
    (gen_random_uuid(), 'Eating Disorder & Body Image Support', '57691c07-ed39-4341-b291-eab27ba2d4da'),
    (gen_random_uuid(), 'Disability-Inclusive Wellness', '57691c07-ed39-4341-b291-eab27ba2d4da'),
    (gen_random_uuid(), 'Accessible Fitness & Recreation', '57691c07-ed39-4341-b291-eab27ba2d4da'),
    (gen_random_uuid(), 'Queer-Affirming Dental & Oral Health', '57691c07-ed39-4341-b291-eab27ba2d4da'),
    (gen_random_uuid(), 'Maternal & Prenatal Care for Queer Families', '57691c07-ed39-4341-b291-eab27ba2d4da')
ON CONFLICT (type_id, label) DO NOTHING;

INSERT INTO "public"."location_tags" ("id","label","type_id") VALUES
    (gen_random_uuid(), 'Queer-Affirming Churches', '4b7c2104-9e63-405e-b336-ba53d79e96c1'),
    (gen_random_uuid(), 'Inclusive Synagogues, Mosques & Temples', '4b7c2104-9e63-405e-b336-ba53d79e96c1'),
    (gen_random_uuid(), 'Interfaith Queer Gatherings', '4b7c2104-9e63-405e-b336-ba53d79e96c1'),
    (gen_random_uuid(), 'Religious Trauma Support', '4b7c2104-9e63-405e-b336-ba53d79e96c1'),
    (gen_random_uuid(), 'Queer Ritual & Spiritual Circles', '4b7c2104-9e63-405e-b336-ba53d79e96c1'),
    (gen_random_uuid(), 'Queer Clergy & Officiants', '4b7c2104-9e63-405e-b336-ba53d79e96c1'),
    (gen_random_uuid(), 'Queer Buddhist, Pagan & Non-Abrahamic Spaces', '4b7c2104-9e63-405e-b336-ba53d79e96c1'),
    (gen_random_uuid(), 'Decolonial & Indigenous Spiritual Practices', '4b7c2104-9e63-405e-b336-ba53d79e96c1')
ON CONFLICT (type_id, label) DO NOTHING;

INSERT INTO "public"."location_tags" ("id","label","type_id") VALUES
    (gen_random_uuid(), 'Legal Aid Clinics', 'ad43b1eb-fe5c-4dcc-8360-0d800a832a50'),
    (gen_random_uuid(), 'Name & ID Change Support', 'ad43b1eb-fe5c-4dcc-8360-0d800a832a50'),
    (gen_random_uuid(), 'Housing Rights & Tenant Advocacy', 'ad43b1eb-fe5c-4dcc-8360-0d800a832a50'),
    (gen_random_uuid(), 'Workplace Rights & Union Allies', 'ad43b1eb-fe5c-4dcc-8360-0d800a832a50'),
    (gen_random_uuid(), 'Immigration & Asylum Legal Support', 'ad43b1eb-fe5c-4dcc-8360-0d800a832a50'),
    (gen_random_uuid(), 'Anti-Discrimination & Civil Rights Services', 'ad43b1eb-fe5c-4dcc-8360-0d800a832a50'),
    (gen_random_uuid(), 'Hate Crime Reporting & Support', 'ad43b1eb-fe5c-4dcc-8360-0d800a832a50'),
    (gen_random_uuid(), 'Police Misconduct & Accountability Resources', 'ad43b1eb-fe5c-4dcc-8360-0d800a832a50'),
    (gen_random_uuid(), 'Transgender Legal Defense', 'ad43b1eb-fe5c-4dcc-8360-0d800a832a50'),
    (gen_random_uuid(), 'LGBTQ+ Prisoner Rights Organizations', 'ad43b1eb-fe5c-4dcc-8360-0d800a832a50')
ON CONFLICT (type_id, label) DO NOTHING;

INSERT INTO "public"."location_tags" ("id","label","type_id") VALUES
    (gen_random_uuid(), 'Queer Sports Leagues & Recreation', '29bf13b3-9c1c-4553-9b4e-a950955e25ac'),   
    (gen_random_uuid(), 'Outdoor & Adventure Groups', '29bf13b3-9c1c-4553-9b4e-a950955e25ac'),
    (gen_random_uuid(), 'Arts & Maker Collectives', '29bf13b3-9c1c-4553-9b4e-a950955e25ac'),
    (gen_random_uuid(), 'Book Clubs & Reading Groups', '29bf13b3-9c1c-4553-9b4e-a950955e25ac'),
    (gen_random_uuid(), 'Queer Film & Media Clubs', '29bf13b3-9c1c-4553-9b4e-a950955e25ac'),
    (gen_random_uuid(), 'Gaming & Esports Communities', '29bf13b3-9c1c-4553-9b4e-a950955e25ac'),
    (gen_random_uuid(), 'Intergenerational Gatherings', '29bf13b3-9c1c-4553-9b4e-a950955e25ac'),
    (gen_random_uuid(), 'Chosen Family Networks', '29bf13b3-9c1c-4553-9b4e-a950955e25ac'),
    (gen_random_uuid(), 'Social Meetups & Interest Groups', '29bf13b3-9c1c-4553-9b4e-a950955e25ac'),
    (gen_random_uuid(), 'Pen Pals & Long-Distance Queer Connection', '29bf13b3-9c1c-4553-9b4e-a950955e25ac')
ON CONFLICT (type_id, label) DO NOTHING;

INSERT INTO "public"."location_tags" ("id","label","type_id") VALUES
    (gen_random_uuid(), 'Queer Libraries & Archives', '513a6caf-22ed-4ccd-944e-e0717e3fb51b'),
    (gen_random_uuid(), 'Queer History & Heritage Projects', '513a6caf-22ed-4ccd-944e-e0717e3fb51b'),
    (gen_random_uuid(), 'Workshops & Trainings: DEI, Allyship & Queer 101', '513a6caf-22ed-4ccd-944e-e0717e3fb51b'),
    (gen_random_uuid(), 'Sex Ed & Body Positivity Programs', '513a6caf-22ed-4ccd-944e-e0717e3fb51b'),
    (gen_random_uuid(), 'K-12 LGBTQ+ Inclusive Education Programs', '513a6caf-22ed-4ccd-944e-e0717e3fb51b'),
    (gen_random_uuid(), 'University LGBTQ+ Groups', '513a6caf-22ed-4ccd-944e-e0717e3fb51b'),
    (gen_random_uuid(), 'Youth Leadership & Civic Programs', '513a6caf-22ed-4ccd-944e-e0717e3fb51b'),
    (gen_random_uuid(), 'Queer Art & Writing Labs', '513a6caf-22ed-4ccd-944e-e0717e3fb51b'),
    (gen_random_uuid(), 'Financial Literacy Workshops', '513a6caf-22ed-4ccd-944e-e0717e3fb51b'),
    (gen_random_uuid(), 'Media Literacy & Representation Resources', '513a6caf-22ed-4ccd-944e-e0717e3fb51b'),
    (gen_random_uuid(), 'Scholarship & Financial Aid for LGBTQ+ Students', '513a6caf-22ed-4ccd-944e-e0717e3fb51b')
ON CONFLICT (type_id, label) DO NOTHING;


INSERT INTO "public"."location_tags" ("id","label","type_id") VALUES
    (gen_random_uuid(), 'Food Pantries & Mutual Aid', '67ab25a0-e838-43a7-9575-d4c995ee4dec'),
    (gen_random_uuid(), 'Emergency Housing & Shelter Access', '67ab25a0-e838-43a7-9575-d4c995ee4dec'),
    (gen_random_uuid(), 'Long-Term Housing Support Services', '67ab25a0-e838-43a7-9575-d4c995ee4dec'),
    (gen_random_uuid(), 'Job Training & Career Navigation', '67ab25a0-e838-43a7-9575-d4c995ee4dec'),
    (gen_random_uuid(), 'Queer Mentorship Programs', '67ab25a0-e838-43a7-9575-d4c995ee4dec'),
    (gen_random_uuid(), 'Technology Access & Digital Literacy', '67ab25a0-e838-43a7-9575-d4c995ee4dec'),
    (gen_random_uuid(), 'Transportation Access & Mobility Support', '67ab25a0-e838-43a7-9575-d4c995ee4dec'),
    (gen_random_uuid(), 'Childcare & Queer Family Support Services', '67ab25a0-e838-43a7-9575-d4c995ee4dec'),
    (gen_random_uuid(), 'Immigration & Document Navigation', '67ab25a0-e838-43a7-9575-d4c995ee4dec'),
    (gen_random_uuid(), 'Trans & Nonbinary Resource Navigators', '67ab25a0-e838-43a7-9575-d4c995ee4dec'),
    (gen_random_uuid(), 'Funeral & End-of-Life Planning', '67ab25a0-e838-43a7-9575-d4c995ee4dec'),
    (gen_random_uuid(), 'Pet Care & Emergency Foster for Queer People in Crisis', '67ab25a0-e838-43a7-9575-d4c995ee4dec')
ON CONFLICT (type_id, label) DO NOTHING;